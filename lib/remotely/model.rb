module Remotely
  class Model
    attr_accessor :attributes

    def initialize(attributes={})
      @attributes = attributes.symbolize_keys
      connect_associations!
    end

    def connect_associations!
      @attributes.each { |key, id| association(key, id) if key =~ /_id$/ }
    end

    def respond_to?(name)
      @attributes.include?(name) or super
    end

  private

    def association(key, id)
      name = key.to_s.gsub("_id", "")
      (class << self; self; end).send(:define_method, name) do
        fetch_association(name, id)
      end
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
