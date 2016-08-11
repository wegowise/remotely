module Remotely
  class Model
    extend  ActiveModel::Naming
    include ActiveModel::Conversion
    include Associations

    class << self
      include Remotely::HTTPMethods

      # Array of attributes to be sent when saving
      attr_reader :savable_attributes

      # Mark an attribute as safe to save. The `save` method
      # will only send these attributes when called.
      #
      # @param [Symbols] *attrs List of attributes to make savable.
      #
      # @example Mark `name` and `age` as savable
      #   attr_savable :name, :age
      #
      def attr_savable(*attrs)
        @savable_attributes ||= []
        @savable_attributes += attrs
        @savable_attributes.uniq!
      end

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
        new(params).tap { |n| n.save }
      end

      alias :create! :create

      # Update every entry with values from +params+.
      #
      # @param [Hash] params Key-Value pairs of attributes to update
      # @return [Boolean] If the update succeeded
      #
      def update_all(params={})
        put uri, params
      end

      alias :update_all! :update_all

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
        where(Hash[name.split("_and_").zip(args)]).first
      end

      def method_missing(name, *args, &block)
        return find_by($1, *args) if name.to_s =~ /^find_by_(.*)!?$/
        super
      end
    end

    delegate :uri, :get, :post, :put, :parse_response, to: :"self.class"

    # @return [Hash] Key-value of attributes and values.
    attr_accessor :attributes

    def initialize(attributes={})
      set_errors(attributes.delete('errors')) if attributes['errors']
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
    def update_attribute(name, value)
      self.attributes[name.to_sym] = value
      save
    end

    # Update multiple attributes.
    #
    # @param [Hash] attrs Hash of attributes/values to update with.
    # @return [Boolean] Did the save succeed.
    #
    def update_attributes(attrs={})
      self.attributes.merge!(attrs.symbolize_keys)
      save
    end

    # Persist this object to the remote API.
    #
    # If the request returns a status code of 201 or 200 
    # (for creating new records and updating existing ones,
    # respectively) it is considered a successful save and returns 
    # the object. Any other status will result in a return value 
    # of false. In addition, the `obj.errors` collection will be 
    # populated with any errors returns from the remote API.
    #
    # For `save` to handle errors correctly, the remote API should
    # return a response body which matches a JSONified ActiveRecord
    # errors object. ie:
    #
    #   {"errors":{"attribute":["message", "message"]}}
    #
    # @return [Boolean] 
    #   Remote API returns 200/201 status:   true
    #   Remote API returns any other status: false
    #
    def save
      method = new_record? ? :post      : :put
      status = new_record? ? 201        : 200
      attrs  = new_record? ? attributes : attributes.slice(*savable_attributes << :id)
      url    = new_record? ? uri        : URL(uri, id)

      resp = public_send(method, url, attrs)
      body = MultiJson.load(resp.body)

      if resp.status == status && !body.nil?
        self.attributes.merge!(body.symbolize_keys)
        true
      else
        set_errors(body.delete("errors")) unless body.nil?
        false
      end
    end

    def savable_attributes
      self.class.savable_attributes || attributes.keys
    end

    # Sets multiple errors with a hash
    def set_errors(hash)
      (hash || {}).each do |attribute, messages|
        Array(messages).each {|m| errors.add(attribute, m) }
      end
    end

    # Track errors with ActiveModel::Errors
    def errors
      @errors ||= ActiveModel::Errors.new(self)
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

    # Assumes that if the object doesn't have an `id`, it's new.
    #
    def new_record?
      self.attributes[:id].nil?
    end

    def persisted?
      !new_record?
    end

    def respond_to?(name, include_all = false)
      self.attributes and self.attributes.include?(name) or super
    end

    def to_json
      MultiJson.dump(self.attributes)
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
      if self.attributes.include?(name) || self.savable_attributes.include?(name)
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
