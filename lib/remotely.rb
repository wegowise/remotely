require "forwardable"
require "faraday"
require "active_support/inflector"
require "active_support/concern"
require "active_support/core_ext/hash/keys"
require "active_model"
require "remotely/ext/url"

module Remotely
  autoload :Collection,   "remotely/collection"
  autoload :Associations, "remotely/associations"
  autoload :Model,        "remotely/model"

  class RemotelyError < StandardError
    def message; MESSAGE; end
  end

  class URLHostError < RemotelyError
    MESSAGE = "URL object missing host"
  end

  class << self
    # @return [Hash] Hash of registered apps (key: name, value: URL)
    attr_accessor :apps

    # Configure applications to be used by models. Accepts a block
    # which specifies multiple apps via the `app` method.
    #
    # @param [Proc] block Configuration block.
    #
    # @example Registers an app named :fun with a URL of "http://fun.com/api/"
    #   Remotely.configure do
    #     app :fun, "http://fun.com/api/"
    #   end
    #
    def configure(&block)
      self.instance_eval(&block)
    end

    # Register an application with Remotely.
    #
    # @param [Symbol] name Placeholder name for the application.
    # @param [String] url URL to the application's API.
    #
    def app(name, url)
      (@apps ||= {})[name] = url
    end

    # Clear all registered apps
    #
    def reset!
      @apps = {}
    end
  end
end

module ActiveRecord
  class Base
    include Remotely
  end
end
