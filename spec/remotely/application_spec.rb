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
  
  it "sets token auth credentials" do
    app = Remotely::Application.new(:name) { token_auth "token", {:foo => :bar} }
    app.token_auth.should == ["token", {:foo => :bar}]
  end
  
  it "sets custom authorization credentials as a string" do
    app = Remotely::Application.new(:name) { authorization "OAuth", "token=foo" }
    app.authorization.should == ["OAuth", "token=foo"]
  end
  
  it "sets custom authorization credentials as a hash" do
    app = Remotely::Application.new(:name) { authorization "OAuth", {:token => :foo} }
    app.authorization.should == ["OAuth", {:token => :foo}]
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
  
  it "has a connection with token auth to the app" do
    app = Remotely::Application.new(:name) do
      url        "http://example.com"
      token_auth "token", {:foo => :bar}
    end
    app.connection.headers["authorization"].should_not be_nil
  end
  
  it "has a connection with custom authorization to the app" do
    app = Remotely::Application.new(:name) do
      url           "http://example.com"
      authorization "OAuth", {:token => :foo}
    end
    app.connection.headers["authorization"].should_not be_nil
  end
end
