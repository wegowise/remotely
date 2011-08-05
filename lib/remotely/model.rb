module Remotely
  class Model
    extend ActiveModel::Naming
    extend Forwardable
    include Associations

    module HTTP
      # HTTP status codes that are represent successful requests
      SUCCESS_STATUSES = (200..299)

      # @return [Symbol] the name of the app the model is fetched from
      attr_accessor :app

      # @return [String] the relative uri to the model's type of resource
      attr_accessor :uri

      # Set or get the app for this model belongs to. If name is passed,
      # it's a setter, otherwise, a getter.
      #
      # @overload app()
      #   Gets the current `app` value.
      #
      # @overload app(name)
      #   Sets the value of `app`.
      #   @param [Symbol] name Name corresponding to an app defined via Remotely.app.
      #
      # @return [Symbol] New app symbol or current value.
      #
      def app(name=nil)
        if name
          @app = name
        else
          if Remotely.apps.size == 1
            @app = Remotely.apps.first.first
          else
            raise RemoteAppError
          end
        end
        @app
      end

      # Set or get the base uri for this model. If name is passed,
      # it's a setter, otherwise, a getter.
      #
      # @overload uri()
      #   Gets the current `uri` value.
      #
      # @overload uri(path)
      #   Sets the value of `uri`.
      #   @param [Symbol] path Relative path to this type of resource.
      #
      # @return [String] New uri or current value.
      #
      def uri(path=nil)
        if path
          @uri = path
        else
          if Remotely.apps.size == 1
            @uri = Remotely.apps.first.last
          else
            raise RemoteAppError
          end
        end
        @uri
      end

      # The connection to the remote API.
      #
      # @return [Faraday::Connection] Connection to the remote API.
      #
      def remotely_connection
        address = Remotely.apps[app]
        address = address + "http://" unless address =~ /^http/

        @connection ||= Faraday::Connection.new(address) do |b|
          b.request :url_encoded
          b.request :json
          b.adapter :net_http
        end
      end

      # GET request.
      #
      # @param [String] uri Relative path of request.
      # @param [Hash] params Query string, in key-value Hash form.
      #
      # @return [Remotely::Collection, Remotely::Model, Hash] If the result
      #   is an array, Collection, if it's a hash, Model, otherwise it's the
      #   parsed response body.
      #
      def get(uri, options={})
        klass = options.delete(:class)
        parse_response(remotely_connection.get { |req| req.url(uri, options) }, klass)
      end

      # POST request.
      #
      # Used mainly to create new resources. Remotely assumes that the
      # remote API will return the newly created object, in JSON form,
      # with the `id` assigned to it.
      #
      # @param [String] uri Relative path of request.
      # @param [Hash] params Request payload. Gets JSON-encoded.
      #
      # @return [Remotely::Collection, Remotely::Model, Hash] If the result
      #   is an array, Collection, if it's a hash, Model, otherwise it's the
      #   parsed response body.
      #
      def post(uri, options={})
        klass = options.delete(:class)
        parse_response(remotely_connection.post(uri, Yajl::Encoder.encode(options)), klass)
      end

      # PUT request.
      #
      # @param [String] uri Relative path of request.
      # @param [Hash] params Request payload. Gets JSON-encoded.
      #
      # @return [Boolean] Was the request successful? (Resulted in a
      #   200-299 response code)
      #
      def put(uri, options={})
        SUCCESS_STATUSES.include?(remotely_connection.put(uri, Yajl::Encoder.encode(options)).status)
      end

      # DELETE request.
      #
      # @param [String] uri Relative path of request.
      #
      # @return [Boolean] Was the resource deleted? (Resulted in a
      #   200-299 response code)
      #
      def delete(uri)
        SUCCESS_STATUSES.include?(remotely_connection.delete(uri).status)
      end

      # Parses the response depending on what was returned. The following
      # table described what gets return in what situations.
      #
      # ------------+------------------+--------------
      # Status Code | Return Body Type | Return Value
      # ------------+------------------+--------------
      #   >= 400    |       N/A        |    false
      # ------------+------------------+--------------
      #   200-299   |      Array       |  Collection
      # ------------+------------------+--------------
      #   200-299   |      Hash        |     Model
      # ------------+------------------+--------------
      #   200-299   |      Other       | Parsed JSON
      # ------------+------------------+--------------
      #
      # @param [Faraday::Response] response Response object
      #
      # @return [Remotely::Collection, Remotely::Model, Other] If the result
      #   is an array, Collection, if it's a hash, Model, otherwise it's the
      #   parsed response body.
      #
      def parse_response(response, klass=nil)
        return false if response.status >= 400

        body  = Yajl::Parser.parse(response.body) rescue nil
        klass = (klass || self)

        case body
        when Array
          Collection.new(body.map { |o| klass.new(o) })
        when Hash
          klass.new(body)
        else
          body
        end
      end
    end

    class << self
      include HTTP

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

      def save(id=nil, params={})
        put URL(uri, id), params
      end

      # Destroy an individual resource.
      #
      # @param [Fixnum] id id of the resource to destroy.
      #
      # @return [Boolean] If the destruction succeeded.
      #
      def destroy(id)
        delete URL(uri, id)
      end
    end

    def_delegators :"self.class", :uri, :get

    # @return [Hash] Key-value of attributes and values.
    attr_accessor :attributes

    def initialize(attributes={})
      self.attributes = attributes.symbolize_keys
      associate!
    end

    # Persist this object to the remote API.
    #
    def save
      self.class.save(self.id, self.attributes)
    end

    # Destroy this object with the might of 60 jotun!
    #
    def destroy
      self.class.destroy(self.id)
    end

    # Re-fetch the resource from the remote API.
    #
    def reload
      self.attributes = get(URL(uri, self.id)).attributes
      self
    end

    # Assumes that if the object doesn't have an `id`, it's new. If you
    # instantiate an object with an `id`... what the crap man?!
    #
    def new_record?
      self.attributes.include?(:id)
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
