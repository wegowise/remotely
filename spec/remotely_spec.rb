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
end
