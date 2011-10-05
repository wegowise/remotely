require "spec_helper"

describe Remotely::HTTPMethods do
  include Remotely::HTTPMethods

  it "raises NonJsonResponseError when HTML is returned on GET" do
    stub_request(:get, %r(/things)).to_return(body: "<html><head><title></title></head></html>")
    expect { get("/things") }.to raise_error(Remotely::NonJsonResponseError)
  end

  it "raises NonJsonResponseError when HTML is returned on POST" do
    stub_request(:post, %r(/things)).to_return(body: "<html><head><title></title></head></html>")
    expect { post("/things") }.to raise_error(Remotely::NonJsonResponseError)
  end

  it "raises NonJsonResponseError when HTML is returned on PUT" do
    stub_request(:put, %r(/things)).to_return(body: "<html><head><title></title></head></html>")
    expect { put("/things") }.to raise_error(Remotely::NonJsonResponseError)
  end

  it "raises NonJsonResponseError when HTML is returned on DELETE" do
    stub_request(:delete, %r(/things)).to_return(body: "<html><head><title></title></head></html>")
    expect { http_delete("/things") }.to raise_error(Remotely::NonJsonResponseError)
  end
end
