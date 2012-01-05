require "forwardable"
require "faraday"
require "active_support/inflector"
require "active_support/concern"
require "active_support/core_ext/hash"
require "active_model"

require "remotely/ext/url"
require "remotely/application"
require "remotely/http_methods"
require "remotely/associations"
require "remotely/model"
require "remotely/collection"

module Remotely
  class RemotelyError < StandardError
    def message; self.class::MESSAGE; end
  end

  class URLHostError < RemotelyError
    MESSAGE = "URL object missing host"
  end

  class RemoteAppError < RemotelyError
    MESSAGE = "No app specified for association with more than one app registered."
  end

  class HasManyForeignKeyError < RemotelyError
    MESSAGE = "has_many associations can use the :foreign_key option."
  end

  class NonJsonResponseError < RemotelyError
    MESSAGE = "Received an HTML response. Expected JSON."
    attr_reader :body

    def initialize(body)
      @body = body
    end
  end

  class << self
    # @return [Hash] Registered application configurations
    def apps
      @apps ||= {}
    end

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
      instance_eval(&block)
    end

    # Register an application with Remotely.
    #
    # @param [Symbol] name Placeholder name for the application.
    # @param [String] url URL to the application's API.
    # @param [Block]  Block defining the attributes of the application.
    #
    def app(name, url=nil, &block)
      if !url && block_given?
        apps[name] = Application.new(name, &block)
      else
        apps[name] = Application.new(name) { url(url) }
      end
    end

    # Clear all registered apps
    #
    def reset!
      @apps = {}
    end
  end
end

module ActiveRecord
  class Base; include Remotely::Associations end
end
