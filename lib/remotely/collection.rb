module Remotely
  class Collection < Array
    # Returns the first Model object with `id`.
    #
    def find(id)
      select { |e| e.id.to_i == id.to_i }.first
    end

    # Returns a new Collection object consisting of all the
    # Model objects matching `attrs`.
    #
    def where(attrs={})
      Collection.new(select { |e| attrs.all? { |k,v| e.send(k) == v } })
    end
  end
end
