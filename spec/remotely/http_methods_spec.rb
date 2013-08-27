require "spec_helper"

describe Remotely::HTTPMethods do
  include Remotely::HTTPMethods

  it "raises NonJsonResponseError when HTML is returned on GET" do
    stub_request(:get, %r(/things)).to_return(body: "<html lang='en'><head><title></title></head></html>")
    expect { get("/things") }.to raise_error(Remotely::NonJsonResponseError)
  end

  it "raises NonJsonResponseError when HTML is returned on POST" do
    stub_request(:post, %r(/things)).to_return(body: "<HTML><HEAD><TITLE></TITLE></HEAD></HTML>")
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

  it "passes the correct headers for post requests" do
    stub_request(:post, %r(/things)).
      to_return(body: "{\"key\":\"value\"}")

    post("/things", headers: {'Content-Type'=>'text/plain'})

    a_request(:post, %r(/things)).
      with(headers: {'Content-Type'=>'text/plain'}).
      should have_been_made
  end

  it "defaults the Content-Type header to be application/json" do
    stub_request(:post, %r(/things)).
      to_return(body: "{\"key\":\"value\"}")

    post("/things")

    a_request(:post, %r(/things)).
      with(headers: {'Content-Type'=>'application/json'}).
      should have_been_made
  end

  it "passes the correct headers for put requests" do
    stub_request(:put, %r(/things)).
      to_return(body: "{\"key\":\"value\"}")

    put("/things", headers: {'Content-Type'=>'application/pdf'})

    a_request(:put, %r(/things)).
      with(headers: {'Content-Type'=>'application/pdf'}).
      should have_been_made
  end
end
