require "faraday"
require "active_support/inflector"
require "active_support/core_ext/hash/keys"
require "remotely/model_struct"

module Remotely
  class << self; attr_accessor :apps, :connections end

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
    attr_accessor :remote_associations

    def has_many_remote(name, options={})
      add_remote_association(name, options)
      define_method(name)       { call_association(name, options)  }
      define_method("#{name}!") { call_association!(name, options) }
    end

    def add_remote_association(name, options)
      @remote_associations     ||= {}
      @remote_associations[name] = {:path => "/#{name}"}.merge(options)
    end
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
    object = fetch_association(name, options)
    instance_variable_set("@#{name}", object)
    instance_variable_get("@#{name}")
  end

  # Retreives the association object from the remote API.
  #
  def fetch_association(name, options)
    parse(connection_for(options).get(path_for(name)).body)
  end

  # Determines the URI for an association object.
  #
  def path_for(name)
    replace_id_in_path(name)
    remote_associations[name][:path] || "/#{name}"
  end

  # List of associations and the options passed when they were created
  #
  def remote_associations
    self.class.remote_associations
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

  # Replaces `:id` in the `:path` options with this instance's
  # id.
  #
  # Since remote associations are declared from the class context,
  # this needs to happen the first time a remote association is
  # accessed. Prior to that there's no such things as an `id`.
  #
  def replace_id_in_path(name)
    assoc = remote_associations[name]
    assoc[:path].gsub!(":id", id.to_s) if assoc[:path]
  end

  # Parses the JSON response and creates a Struct from it. Whatever
  # attributes the API returns if what gets set on the resulting object.
  #
  def parse(response)
    response = Yajl::Parser.parse(response)
    return [] if response.empty?
    response.map { |o| ModelStruct.new(o) }
  end
end
