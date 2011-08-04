require "spec_helper"

describe URL do
  it "takes n number of arguments and joins them" do
    URL.new("a", "b", "c").should == "/a/b/c"
  end

  it "removes duplicate slashes" do
    URL.new("a", "/", "b").should == "/a/b"
  end

  it "is comparable" do
    URL.new("a", "b").should == URL.new("a", "b")
  end

  it "is addable" do
    (URL.new("a", "b") + URL.new("c")).to_s.should == "/a/b/c"
  end

  it "is subtractable" do
    (URL.new("a", "b") - URL.new("b")).to_s.should == "/a"
  end

  it "creatable using URL()" do
    URL("a", "b").should == "/a/b"
  end
end
