module Remotely
  module HTTPMethods
    # HTTP status codes that are represent successful requests
    SUCCESS_STATUSES = (200..299)

    # @return [Symbol] the name of the app the model is fetched from
    attr_accessor :app

    # @return [String] the relative uri to the model's type of resource
    attr_accessor :uri

    # Set or get the app for this model belongs to. If name is passed,
    # it's a setter, otherwise, a getter.
    #
    # In getter form, if a model didn't declare which app it is
    # associated with and there is only one registered app, it
    # will default to that app.
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
      @app = (@app || Remotely.apps[name] || only_registered_app)
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
      @uri = (@uri || path)
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
    def get(path, options={})
      path     = expand(path)
      klass    = options.delete(:class)
      parent   = options.delete(:parent)

      before_request(path, :get, options)

      response = app.connection.get { |req| req.url(path, options) }
      parse_response(raise_if_html(response), klass, parent)
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
    def post(path, options={})
      path   = expand(path)
      klass  = options.delete(:class)
      parent = options.delete(:parent)
      body   = options.delete(:body) || MultiJson.dump(options)

      before_request(path, :post, body)
      raise_if_html(app.connection.post(path, body))
    end

    # PUT request.
    #
    # @param [String] uri Relative path of request.
    # @param [Hash] params Request payload. Gets JSON-encoded.
    #
    # @return [Boolean] Was the request successful? (Resulted in a
    #   200-299 response code)
    #
    def put(path, options={})
      path = expand(path)
      body = options.delete(:body) || MultiJson.dump(options)

      before_request(path, :put, body)
      raise_if_html(app.connection.put(path, body))
    end

    # DELETE request.
    #
    # @param [String] uri Relative path of request.
    #
    # @return [Boolean] Was the resource deleted? (Resulted in a
    #   200-299 response code)
    #
    def http_delete(path)
      path = expand(path)
      before_request(path, :delete)
      response = raise_if_html(app.connection.delete(path))
      SUCCESS_STATUSES.include?(response.status)
    end

    # Remove the leading slash because Faraday considers
    # it to be absolute path and ignores any prefixes. eg:
    #
    #   c = Faraday::Connection.new("http://foo.com/api")
    #   c.get("users")  # => /api/users (Good)
    #   c.get("/users") # => /users     (Bad)
    #
    # @example
    #   Remotely.configure { app :thingapp, "http://example.com/api" }
    #   Model.expand("/members") # => "members"
    #
    def expand(path)
      path.gsub(%r(^/), "")
    end

    # Gets called before a request. Override to add logging, etc.
    #
    def before_request(uri, http_verb = :get, options = {})
      if ENV['REMOTELY_DEBUG']
        puts "-> #{http_verb.to_s.upcase} #{uri}" 
        puts "   #{options.inspect}"
      end
    end

    def raise_if_html(response)
      if response.body =~ %r(<html>)
        raise Remotely::NonJsonResponseError.new(response.body)
      end
      response
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
    def parse_response(response, klass=nil, parent=nil)
      return false if response.status >= 400

      body  = MultiJson.load(response.body) rescue nil
      klass = (klass || self)

      case body
      when Array
        Collection.new(parent, klass, body.map { |o| klass.new(o) })
      when Hash
        klass.new(body)
      else
        body
      end
    end

  private

    def only_registered_app
      Remotely.apps.size == 1 ? Remotely.apps.first.last : nil
    end
  end
end
