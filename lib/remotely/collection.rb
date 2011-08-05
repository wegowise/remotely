module Remotely
  class Collection < Array
    # Returns the first Model object with `id`.
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
      Collection.new(select(&block))
    end

    # Mimic an ActiveRecord::Relation, but just return self since
    # that's already an array.
    #
    # @return [Remotely::Collection] self
    #
    def all
      self
    end
  end
end
