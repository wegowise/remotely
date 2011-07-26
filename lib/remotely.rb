require "faraday"
require "active_support/inflector"
require "active_support/core_ext/hash/keys"
require "remotely/model"

module Remotely
  class << self; attr_accessor :apps, :connections end

  attr_accessor :remote_associations

  # Register an app and it's url with Remotely. Should be done
  # via `Remotely.configure`.
  #
  def self.app(name, url)
    @apps        ||= {}
    @connections ||= {}
    url = "http://#{url}" unless url =~ %r[^http://]
    @apps[name] = url
  end

  # Clear all apps and connections.
  #
  def self.reset!
    @apps        = {}
    @connections = {}
  end

  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_many_remote(name, options={})
      options.merge!(:type => :has_many)
      define_method(name)       { call_association(name, options)  }
      define_method("#{name}!") { call_association!(name, options) }
    end

    def has_one_remote(name, options={})
      options.merge!(:type => :has_one)
      define_method(name)       { call_association(name, options)  }
      define_method("#{name}!") { call_association!(name, options) }
    end

    def belongs_to_remote(name, options={})
      options.merge!(:type => :belongs_to)
      define_method(name)       { call_association(name, options)  }
      define_method("#{name}!") { call_association!(name, options) }
    end
  end

private

  def add_remote_association(name, options)
    @remote_associations     ||= {}
    @remote_associations[name] = options
  end

  # Returns a cached version of the association object, or fetches
  # it if it has not already been.
  #
  def call_association(name, options)
    call_association!(name, options) unless instance_variable_defined?("@#{name}")
    instance_variable_get("@#{name}")
  end

  # Fetches a new version of the object regardless of whether a cached
  # version exists of not.
  #
  def call_association!(name, options)
    add_remote_association(name, options)
    instance_variable_set("@#{name}", fetch_association(name, options))
    instance_variable_get("@#{name}")
  end

  # Retreives the association object from the remote API.
  #
  def fetch_association(name, options)
    type     = remote_associations[name][:type]
    path     = path_for(name, type)
    response = connection_for(options).get(path)
    parse(response.body, type)
  rescue Exception
    nil
  end

  # Determines the URI for an association object.
  #
  def path_for(name, type)
    path = remote_associations[name][:path] || send(:"#{type}_default_path", name)
    path = self.instance_exec(&path) if path.is_a?(Proc)
    interpolate_attributes(path)
  end

  def has_many_default_path(name)
    "/#{name}"
  end

  def has_one_default_path(name)
    "/#{self.class.to_s.downcase.pluralize}/#{self.id}/#{name}"
  end

  def belongs_to_default_path(name)
    if respond_to?(:"#{name}_id")
      "/#{name.pluralize}/#{send("#{name}_id")}"
    else
      raise "Must specify path for belongs_to_remote associations."
    end
  end

  def interpolate_attributes(path)
    path.gsub(%r{:[^/]+}) { |m| public_send(m.gsub(":", "").to_sym).to_s }
  end

  # Creates or retreives the connection for a specific application.
  # Apps are set up via `Remotely.configure`.
  #
  def connection_for(options)
    name, url = *app_for(options[:app])
    raise Exception, "Must specify the association's app." unless name && url
    Remotely.connections[name] ||= Faraday.new(:url => url)
  end

  def app_for(appname)
    return Remotely.apps.to_a.flatten if Remotely.apps.size == 1
    Remotely.apps.assoc(appname)
  end

  # Parses the JSON response and creates a Struct from it. Whatever
  # attributes the API returns if what gets set on the resulting object.
  #
  def parse(response, type)
    response = Yajl::Parser.parse(response)
    return [] if response.empty?

    case type
    when :has_many
      response.map { |o| Model.new(o) }
    else
      Model.new(response)
    end
  end
end

module ActiveRecord
  class Base; include Remotely; end
end
