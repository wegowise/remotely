require "remotely"
require 'webmock/rspec'
WebMock.disable_net_connect!
require "support/webmock"
require "support/test_classes"

RSpec.configure do |c|
  c.before do
    WebmockHelpers.stub!
    Remotely.reset!
    Remotely.configure { app :adventure_app, "http://localhost:1234" }
  end

  def to_json(obj)
    MultiJson.dump(obj)
  end
end
