require "faraday"
require "active_support/inflector"
require "remotely/ext/hash"

# = OMG Remotely!
#
# Remotely lets you specify associations for your models that should
# be fetched from a remote API instead of the database.
#
# == Setup
#
# First thing to do is define your remote API's. You can define as many as
# you want. Apps are how certain associations know where to fetch themselves
# from.
#
#   # config/intitializers/remotely.rb
#   Remotely.app :legsapp, "http://omgsomanylegs.com/api/v1"
#
# === Number of Apps Registered with Remotely
#
# If you only register a single app with Remotely, all remote associations
# will try to be fetched through that app. In this case, you can omit the
# `:app` parameter when defining your associations.
#
# If you register more than one app, each association will also need to
# specify which app it should come from. Look at the next section for
# information on defining that option.
#
# == Associations
#
# Remote associations are defined using `has_many_remote` in the same way
# you would define a normal ActiveRecord association.
#
#   class Millepied < ActiveRecord::Base
#     include Remotely
#     has_many_remote :legs
#   end
#
#
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

  private

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
    app = options[:app]
    raise Exception, "Must specify the association's app." unless app
    Remotely.connections[app] ||= Faraday.new(:url => Remotely.apps[app])
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
    response = connect_associations(response)
    return [] if response.empty?
    response.map { |o| Struct.new(*o.symbolize_keys.keys).new(*o.values) }
  end

  # Looks through the objects retrieved from the remote API for any
  # attributes ending in "_id". If found, it'll attempt to find them
  # via their corresponding model class.
  #
  # TODO: clean up; this is gross.
  #
  def connect_associations(response)
    response.map do |object|
      assocs  = Hash[object.keys.select { |k| k =~ /_id$/ }.map do |key|
        no_id = key.gsub("_id", "")
        klass = no_id.classify.constantize
        [no_id, klass.find(object[key])]
      end]
      object.merge(assocs)
    end
  end

end
