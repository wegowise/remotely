class URL
  include Comparable

  def initialize(*args)
    @url = "/" + args.flatten.compact.join("/")
    @url.gsub! %r[/{2,}], "/"
    @url.gsub! %r[/$], ""
    define_delegation_methods
  end

  def +(other)
    URL.new(to_s, other.to_s)
  end

  def -(other)
    URL.new(to_s.gsub(other.to_s, ""))
  end

  def <=>(other)
    @url <=> other.to_s
  end

  def to_s
    @url
  end

private

  def define_delegation_methods
    @url.public_methods(false).each do |name|
      metaclass.class_eval do
        define_method(name) { |*args| @url.send(name, *args) }
      end
    end
  end

  def metaclass
    (class << self; self; end)
  end
end

def URL(*args)
  URL.new(*args)
end
