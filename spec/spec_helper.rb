require "remotely"
require 'webmock/rspec'
require "yajl"
WebMock.disable_net_connect!

RSpec.configure do |c|
  c.before do
    WebMock::API.stub_request(:get, %r[/trucks.*]).to_return(body: to_json([{:size => 17, :width => 10}]))
  end

  def to_json(obj)
    Yajl::Encoder.encode(obj)
  end
end
