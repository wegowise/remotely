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
      if @app.nil? && name.nil? && Remotely.apps.size == 1
        name = Remotely.apps.first.first
      end

      (name and @app = name) or @app
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
      (path and @uri = path) or @uri
    end

    # The connection to the remote API.
    #
    # @return [Faraday::Connection] Connection to the remote API.
    #
    def remotely_connection
      address = Remotely.apps[app]
      address = "http://#{address}" unless address =~ /^http/

      @connection ||= Faraday::Connection.new(address) do |b|
        b.request  :url_encoded
        b.adapter  :net_http
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
      klass  = options.delete(:class)
      parent = options.delete(:parent)
      before_request(uri, :get, options)
      parse_response(remotely_connection.get { |req| req.url(uri, options) }, klass, parent)
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
      klass  = options.delete(:class)
      parent = options.delete(:parent)
      body   = options.delete(:body) || Yajl::Encoder.encode(options)

      before_request(uri, :post, body)
      parse_response(remotely_connection.post(uri, body), klass, parent)
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
      body = options.delete(:body) || Yajl::Encoder.encode(options)

      before_request(uri, :put, body)
      remotely_connection.put(uri, body)
    end

    # DELETE request.
    #
    # @param [String] uri Relative path of request.
    #
    # @return [Boolean] Was the resource deleted? (Resulted in a
    #   200-299 response code)
    #
    def http_delete(uri)
      before_request(uri, :delete)
      SUCCESS_STATUSES.include?(remotely_connection.delete(uri).status)
    end

    # Gets called before a request. Override to add logging, etc.
    def before_request(uri, http_verb = :get, options = {})
      if ENV['REMOTELY_DEBUG']
        puts "-> #{http_verb.to_s.upcase} #{uri}" 
        puts "   #{options.inspect}"
      end
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

      body  = Yajl::Parser.parse(response.body) rescue nil
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
  end
end
