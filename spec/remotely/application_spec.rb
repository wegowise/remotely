require "spec_helper"

describe Remotely::Application do
  it "sets the url" do
    app = Remotely::Application.new(:name) { url "http://omg.com" }
    app.url.should == "http://omg.com"
  end

  it "defaults the url to http" do
    app = Remotely::Application.new(:name) { url "omg.com" }
    app.url.should == "http://omg.com"
  end

  it "sets basic auth credentials" do
    app = Remotely::Application.new(:name) { basic_auth "user", "pass" }
    app.basic_auth.should == ["user", "pass"]
  end

  it "has a connection to the app" do
    app = Remotely::Application.new(:name) { url "http://example.com" }
    app.connection.should be_a Faraday::Connection
  end

  it "has a connection with basic auth to the app" do
    app = Remotely::Application.new(:name) do
      url        "http://example.com"
      basic_auth "user", "pass"
    end
    app.connection.headers["authorization"].should_not be_nil
  end
end
