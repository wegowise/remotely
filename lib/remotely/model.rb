module Remotely
  class Model
    attr_accessor :attributes

    # Create model class and instantiate a new one with attributes.
    #
    # New classes are made on the fly so that the ActiveModel
    # functionality that depends on `self.class` will work correctly.
    #
    # For example, ActiveRecord assumes every model's class has a
    # method called `model_name` which it uses when creating id's and
    # class's for HTML elements via `form_for`.
    #
    def self.create(name, attributes={})
      klassname = name.to_s.classify

      unless Object.const_defined?(klassname)
        klass = Class.new(self)
        klass.send(:extend, ActiveModel::Naming)
        Object.const_set(klassname, klass)
      end

      Object.const_get(klassname).new(attributes)
    end

    # User `Model.create` to instantiate new Model objects.
    #
    def initialize(attributes={})
      @attributes = attributes.symbolize_keys
      connect_associations!
    end

    # Mimics ActiveRecord::AttributeMethods::PrimaryKey in order
    # to make Remotely::Model's compatible with Rails form helpers.
    #
    def to_key
      @attributes.include?(:id) ? [@attributes[:id]] : nil
    end

    def respond_to?(name)
      @attributes.include?(name) or super
    end

    def to_json
      Yajl::Encoder.encode(attributes)
    end

  private

    def metaclass
      (class << self; self; end)
    end

    def connect_associations!
      @attributes.each { |key, id| association(key, id) if key =~ /_id$/ }
    end

    def association(key, id)
      name = key.to_s.gsub("_id", "")
      metaclass.send(:define_method, name) { fetch_association(name, id) }
    end

    def fetch_association(name, id)
      unless instance_variable_defined?("@#{name}")
        instance_variable_set("@#{name}", name.classify.constantize.find(id))
      end
      instance_variable_get("@#{name}")
    end

    def method_missing(name, *args, &block)
      if @attributes.include?(name)
        @attributes[name]
      elsif name =~ /(.*)\?$/ && @attributes.include?($1.to_sym)
        !!@attributes[$1.to_sym]
      else
        super
      end
    end
  end
end
