require "spec_helper"

describe Remotely do
  before do
    Remotely.reset!
  end

  it "is configurable" do
    Remotely.configure { app :configapp, "localhost:2222" }
    Remotely.apps.should include(:configapp)
  end

  it "is resetable" do
    Remotely.configure { app :configapp, "localhost:2222" }
    Remotely.reset!
    Remotely.apps.should be_empty
  end
end
