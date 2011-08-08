module Remotely
  class Collection < Array
    def initialize(parent, klass, *args, &block)
      @parent = parent
      @klass  = klass
      super(*args, &block)
    end

    # Returns the first Model object with +id+.
    #
    # @param [Fixnum] id id of the record
    # @return [Remotely::Model] Model object with that id
    #
    def find(id)
      select { |e| e.id.to_i == id.to_i }.first
    end

    # Returns a new Collection object consisting of all the
    # Model objects matching `attrs`.
    #
    # @param [Hash] attrs Search criteria in key-value form
    # @return [Remotely::Collection] New collection of elements matching
    #
    def where(attrs={}, &block)
      block = lambda { |e| attrs.all? { |k,v| e.send(k) == v }} unless block_given?
      Collection.new(@parent, @klass, select(&block))
    end

    # Mimic an ActiveRecord::Relation, but just return self since
    # that's already an array.
    #
    # @return [Remotely::Collection] self
    #
    def all
      self
    end

    # Order the result set by a specific attribute.
    #
    # @example Sort by +name+
    #   Thing.where(:type => "awesome").order(:name)
    #
    # @result [Remotely::Collection] A new, ordered, Collection.
    #
    def order(attribute)
      Collection.new(@parent, @klass, sort_by(&attribute))
    end

    # Instantiate a new model object, pre-build with a foreign key
    # attribute set to it's parent, and add it to itself.
    #
    # NOTE: Does not persist the new object. You must call +save+ on the
    # new object to persist it. To instantiate and persist in one operation
    # @see #create.
    #
    # @param [Hash] attrs Attributes to instantiate the new object with.
    # @return [Remotely::Model] New model object
    #
    def build(attrs={})
      attribute  = "#{@parent.class.model_name.element.to_sym}_id".to_sym
      value      = @parent.id
      attrs.merge!(attribute => value)

      @klass.new(attrs).tap { |m| self << m }
    end

    # Same as #build, but saves the new model object as well.
    #
    # @see #build
    #
    def create(attrs={})
      build(attrs).tap { |m| m.save }
    end
  end
end
