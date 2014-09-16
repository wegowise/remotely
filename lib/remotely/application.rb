module Remotely
  class Application
    attr_reader :name

    def initialize(name, &block)
      @name = name
      instance_eval(&block)
    end

    # Set or get the applications base url.
    #
    # @param [String] url Base url to the appplication
    #
    def url(url=nil)
      return @url unless url
      @url = URI.parse(set_scheme(url)).to_s
    end

    # Set or get BasicAuth credentials.
    #
    # @param [String] user BasicAuth user
    # @param [String] password BasicAuth password
    #
    def basic_auth(user=nil, password=nil)
      return @basic_auth unless user && password
      @basic_auth = [user, password]
    end
    
    # Set or get the Authorization header.
    #  - As seen here: https://github.com/lostisland/faraday/blob/master/lib/faraday/connection.rb#L204
    # 
    # @param [String] token   - The String token.
    # @param [Hash]   options - Optional Hash of extra token options.
    #
    def token_auth(token=nil, options={})
      return @token_auth unless token
      @token_auth = [token, options]
    end
    
    # Set or get a custom Authorization header.
    #  - As seen here: https://github.com/lostisland/faraday/blob/master/lib/faraday/connection.rb#L227
    # 
    # @param [String]       type    - The String authorization type.
    # @param [String|Hash]  token   - The String or Hash token.  A String value is taken literally, and a Hash is encoded into comma separated key/value pairs.
    #
    def authorization(type=nil, token=nil)
      return @authorization unless type && token
      @authorization = [type, token]
    end

    def use_middleware(klass, options = {})
      middleware << [klass, options]
    end

    def middleware
      @middleware ||= []
    end

    # Connection to the application (with BasicAuth if it was set).
    #
    def connection
      return unless @url

      @connection ||= Faraday::Connection.new(@url) do |b|
        middleware.each { |m, opts| b.use(m, opts) }
        b.request :url_encoded
        b.adapter :net_http
      end
      
      @connection.basic_auth(*@basic_auth)        if @basic_auth
      @connection.token_auth(*@token_auth)        if @token_auth
      @connection.authorization(*@authorization)  if @authorization
      @connection
    end

  private

    def set_scheme(url)
      url =~ /^http/ ? url : "http://#{url}"
    end
  end
end
