class URL
  include Comparable

  def initialize(*args)
    @url = args.flatten.compact.join("/")
    @url.gsub! %r[^/|/$], ""
  end

  def to_s
    @url
  end

  def +(other)
    URL.new(@url, other.to_s)
  end

  def -(other)
    URL.new(to_s.gsub(other.to_s, ""))
  end

  def <=>(other)
    @url <=> other.to_s
  end
end

def URL(*args)
  URL.new(*args)
end
