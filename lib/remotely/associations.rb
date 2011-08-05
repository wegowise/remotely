module Remotely
  module Associations
    module ClassMethods
      attr_accessor :remote_associations

      def has_many_remote(name, options={})
        define_association_method(:has_many, name, options)
      end

      def has_one_remote(name, options={})
        define_association_method(:has_one, name, options)
      end

      def belongs_to_remote(name, options={})
        define_association_method(:belongs_to, name, options)
      end

    private

      def define_association_method(type, name, options)
        self.remote_associations     ||= {}
        self.remote_associations[name] = options.merge(type: type)
        define_method(name) { |reload=false| call_association(reload, name) }
      end

      def inherited(base)
        base.remote_associations = self.remote_associations
        base.extend(ClassMethods)
        base.extend(Remotely::Model::HTTP)
        super
      end
    end

    def remote_associations
      self.class.remote_associations ||= {}
    end

    def path_to(name, type)
      options = remote_associations[name]
      base    = base_class.model_name.element.pluralize
      path    = options[:path] || name.to_s.pluralize
      fkey    = options[:foreign_key] || :"#{name}_id"

      case type
      when :has_many, :has_one
        interpolate URL(base, self.id, path)
      when :belongs_to
        interpolate URL(path, public_send(fkey))
      end
    end

    def base_class
      return self.class if self.class.superclass == ActiveRecord::Base

      klass = self.class.superclass
      while true
        return klass if klass.superclass == ActiveRecord::Base
        klass = klass.superclass
      end
    end

    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end

  private

    def call_association(reload, name)
      fetch_association(name) if reload || association_undefined?(name)
      get_association(name)
    end

    def fetch_association(name)
      type     = remote_associations[name][:type]
      klass    = name.to_s.classify.constantize
      response = self.class.get(path_to(name, type), :class => klass)
      debugger
      response = response.first if type == :has_one

      set_association(name, response)
    end

    def get_association(name)
      instance_variable_get("@#{name}")
    end

    def set_association(name, value)
      instance_variable_set("@#{name}", value)
    end

    def association_undefined?(name)
      !instance_variable_defined?("@#{name}")
    end

    def interpolate(string)
      string.to_s.gsub(%r{:\w+}) { |match| public_send(match.tr(":", "")) }
    end
  end
end
