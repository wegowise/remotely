require "spec_helper"

describe Remotely do
  before do
    Remotely.reset!
  end

  it "is resetable" do
    Remotely.configure { app :configapp, "localhost:2222" }
    Remotely.reset!
    Remotely.apps.should be_empty
  end

  it "is configurable with the old, non-block style" do
    Remotely.configure { app :configapp, "localhost:2222" }
    Remotely.apps[:configapp].url.should == "http://localhost:2222"
  end

  it "is configurable with a block" do
    Remotely.configure { app(:configapp) { url "localhost:2222" } }
    Remotely.apps[:configapp].url.should == "http://localhost:2222"
  end

  it "saves the basic auth credentials" do
    Remotely.configure { app(:appname) { basic_auth "user", "pass" }}
    Remotely.apps[:appname].basic_auth.should == ["user", "pass"]
  end
  
  it "saves the token auth credentials" do
    Remotely.configure { app(:appname) { token_auth "token", {:foo => :bar} }}
    Remotely.apps[:appname].token_auth.should == ["token", {:foo => :bar}]
  end
  
  it "saves the authorization credentials as a string" do
    Remotely.configure { app(:appname) { authorization "OAuth", "token=foo" }}
    Remotely.apps[:appname].authorization.should == [ "OAuth", "token=foo" ]
  end
  
  it "saves the authorization credentials as a hash" do
    Remotely.configure { app(:appname) { authorization "OAuth", {:token => :foo} }}
    Remotely.apps[:appname].authorization.should == [ "OAuth", {:token => :foo}]
  end
end
