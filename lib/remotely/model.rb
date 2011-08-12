module Remotely
  class Model
    extend ActiveModel::Naming
    extend Forwardable
    include Associations

    class << self
      include Remotely::HTTPMethods

      # Fetch all entries.
      #
      # @return [Remotely::Collection] collection of entries
      #
      def all
        get uri
      end

      # Retreive a single object. Combines `uri` and `id` to determine
      # the URI to use.
      #
      # @param [Fixnum] id The `id` of the resource.
      #
      # @example Find the User with id=1
      #   User.find(1)
      #
      # @return [Remotely::Model] Single model object.
      #
      def find(id)
        get URL(uri, id)
      end

      # Fetch the first record matching +attrs+ or initialize a new instance
      # with those attributes.
      #
      # @param [Hash] attrs Attributes to search by, and subsequently instantiate
      #   with, if not found.
      #
      # @return [Remotely::Model] Fetched or initialized model object
      #
      def find_or_initialize(attrs={})
        where(attrs).first or new(attrs)
      end

      # Fetch the first record matching +attrs+ or initialize and save a new
      # instance with those attributes.
      #
      # @param [Hash] attrs Attributes to search by, and subsequently instantiate
      #   and save with, if not found.
      #
      # @return [Remotely::Model] Fetched or initialized model object
      #
      def find_or_create(attrs={})
        where(attrs).first or create(attrs)
      end

      # Search the remote API for a resource matching conditions specified
      # in `params`. Sends `params` as a url-encoded query string. It
      # assumes the search endpoint is at "/resource_plural/search".
      #
      # @param [Hash] params Key-value pairs of attributes and values to search by.
      #
      # @example Search for a person by name and title
      #   User.where(:name => "Finn", :title => "The Human")
      #
      # @return [Remotely::Collection] Array-like collection of model objects.
      #
      def where(params={})
        get URL(uri, "search"), params
      end

      # Creates a new resource.
      #
      # @param [Hash] params Attributes to create the new resource with.
      #
      # @return [Remotely::Model, Boolean] If the creation succeeds, a new
      #   model object is returned, otherwise false.
      #
      def create(params={})
        post uri, params
      end
      alias :create! :create

      # Save a record.
      #
      # @param [Fixnum, nil] id id of the record to save
      # @param [Hash] params Attributes of the record to save
      #
      # @return [Boolean] Did the save succeed?
      #
      def save(id=nil, params={})
        return create(params) if id.nil?
        put URL(uri, id), params
      end
      alias :save! :save

      # Update every entry with values from +params+.
      #
      # @param [Hash] params Key-Value pairs of attributes to update
      # @return [Boolean] If the update succeeded
      #
      def update_all(params={})
        put uri, params
      end

      # Destroy an individual resource.
      #
      # @param [Fixnum] id id of the resource to destroy.
      #
      # @return [Boolean] If the destruction succeeded.
      #
      def destroy(id)
        http_delete URL(uri, id)
      end
      alias :destroy! :destroy

      # Remotely models don't support single table inheritence
      # so the base class is always itself.
      #
      def base_class
        self
      end

    private

      # Search by one or more attribute and their values.
      #
      # @param [String, Symbol] name The attribute name
      # @param [String, Symbol] value Value to search by
      #
      # @see .where
      #
      def find_by(name, *args)
        where(Hash[name.split("_and_").zip(args)])
      end

      def method_missing(name, *args, &block)
        return find_by($1, *args) if name.to_s =~ /^find_by_(.*)!?$/
        super
      end
    end

    def_delegators :"self.class", :uri, :get, :post, :put

    # @return [Hash] Key-value of attributes and values.
    attr_accessor :attributes

    def initialize(attributes={})
      self.attributes = attributes.symbolize_keys
      associate!
    end

    # Update a single attribute.
    #
    # @param [Symbol, String] name Attribute name
    # @param [Mixed] value New value for the attribute
    # @param [Boolean] should_save Should it save after updating
    #   the attributes. Default: true
    # @return [Boolean, Mixed] Boolean if the it tried to save, the
    #   new value otherwise.
    #
    def update_attribute(name, value, should_save=true)
      self.attributes[name.to_sym] = value
      save if should_save
    end

    # Update multiple attributes.
    #
    # @param [Hash] attrs Hash of attributes/values to update with.
    # @return [Boolean] Did the save succeed.
    #
    def update_attributes(attrs={})
      @attribute_cache = self.attributes.dup
      attrs.each { |key, value| update_attribute(key, value, false) }

      if save
        true
      else
        self.attributes = @attribute_cache
        false
      end
    end

    # Persist this object to the remote API.
    #
    def save
      self.class.save(id, self.attributes)
    end

    # Destroy this object with the might of 60 jotun!
    #
    def destroy
      self.class.destroy(id)
    end

    # Re-fetch the resource from the remote API.
    #
    def reload
      self.attributes = get(URL(uri, id)).attributes
      self
    end

    def id
      self.attributes[:id]
    end

    # Assumes that if the object doesn't have an `id`, it's new. If you
    # instantiate an object with an `id`... why?
    #
    def new_record?
      !self.attributes[:id]
    end

    # Mimics ActiveRecord::AttributeMethods::PrimaryKey in order
    # to make Remotely::Model's compatible with Rails form helpers.
    #
    def to_key
      self.attributes.include?(:id) ? [self.attributes[:id]] : nil
    end

    def respond_to?(name)
      self.attributes.include?(name) or super
    end

    def to_json
      Yajl::Encoder.encode(self.attributes)
    end

  private

    def metaclass
      (class << self; self; end)
    end

    # Finds all attributes that match `*_id`, and creates a method for it,
    # that will fetch that record. It uses the `*` part of the attribute
    # to determine the model class and calls `find` on it with the value
    # if the attribute.
    #
    def associate!
      self.attributes.select { |k,v| k =~ /_id$/ }.each do |key, id|
        name = key.to_s.gsub("_id", "")
        metaclass.send(:define_method, name) { |reload=false| fetch(name, id, reload) }
      end
    end

    def fetch(name, id, reload)
      klass = name.to_s.classify.constantize
      set_association(name, klass.find(id)) if reload || association_undefined?(name)
      get_association(name)
    end

    def method_missing(name, *args, &block)
      if self.attributes.include?(name)
        self.attributes[name]
      elsif name =~ /(.*)=$/ && self.attributes.include?($1.to_sym)
        self.attributes[$1.to_sym] = args.first
      elsif name =~ /(.*)\?$/ && self.attributes.include?($1.to_sym)
        !!self.attributes[$1.to_sym]
      else
        super
      end
    end
  end
end
