class URL
  include Comparable

  def initialize(*args)
    @url = "/" + args.flatten.compact.join("/")
    @url.gsub! %r[/{2,}], "/"
    @url.gsub! %r[/$], ""
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
end

def URL(*args)
  URL.new(*args)
end
