require "spec_helper"

describe Remotely do
  class Truck; include Remotely; attr_accessor :id; end

  let(:model) { Truck.new }
  let(:conn)  { mock(Faraday) }
  let(:resp)  { mock.as_null_object }

  before do
    Remotely.reset!
    Remotely.app :wheelapp, "localhost:5432"

    resp.stub(:body) { "[]" }
    conn.stub(:get)  { resp }
    Faraday.stub(:new).and_return(conn)
  end

  it "stores app names and their urls" do
    Remotely.app :importer, "localhost:1234"
    Remotely.apps[:importer].should == "http://localhost:1234"
  end

  describe "has_many_remote" do
    before do
      Truck.has_many_remote :wheels, :app => :wheelapp, :path => "/trucks/:id/wheels"
      model.id = 2
    end

    it "creates a method for each association" do
      model.should respond_to :wheels
    end

    it "defaults the path to /resource_name" do
      Truck.has_many_remote :wheels
      model.remote_associations[:wheels][:path].should == "/wheels"
    end

    it "takes the :path option as precedence" do
      Truck.has_many_remote :wheels, :path => "/grapes"
      model.remote_associations[:wheels][:path].should == "/grapes"
    end

    it "supports :id substitution for :path once called" do
      model.wheels
      model.remote_associations[:wheels][:path].should == "/trucks/2/wheels"
    end

    it "accepts the app where the association is found" do
      model.remote_associations[:wheels][:app].should == :wheelapp
    end

    it "requests the full url" do
      conn.should_receive(:get).with("/trucks/2/wheels").and_return(resp)
      model.wheels
    end
  end

  describe "retreived objects" do
    before do
      Truck.has_many_remote :wheels, :app => :wheelapp, :path => "/trucks/:id/wheels"
      model.id = 2
      resp.stub(:body) { "[{\"size\":17,\"width\":10}]" }
    end

    it "returns an array of objects" do
      model.wheels.should respond_to(:each)
    end

    it "returns struct like objects" do
      model.wheels[0].should respond_to(:size)
    end

    it "caches retreived objects and doesn't retreive them again" do
      model.wheels
      Remotely.connections[:wheelapp].should_not_receive(:get)
      model.wheels
    end

    it "forces re-retreival with the bang method" do
      model.wheels
      Remotely.connections[:wheelapp].should_receive(:get)
      model.wheels!
    end

    it "connects associations on the client side" do
      class User; end
      resp.stub(:body) { "[{\"user_id\":1}]" }
      User.should_receive(:find).with(1)
      model.wheels
    end
  end
end
