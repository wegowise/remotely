# require "spec_helper"
#
# describe Remotely do
#   class Truck
#     include Remotely
#     attr_accessor :id, :owner_id
#   end
#
#   let(:model) { Truck.new.tap { |t| t.id = 2 }}
#   let(:conn)  { mock(Faraday) }
#   let(:resp)  { mock.as_null_object }
#
#   before do
#     Remotely.reset!
#     resp.stub(:body) { "[]" }
#     conn.stub(:get)  { resp }
#     Faraday.stub(:new).and_return(conn)
#   end
#
#   it "is configurable" do
#     Remotely.configure { app :configapp, "localhost:2222" }
#     Remotely.connections.should include(:configapp)
#   end
#
#   describe "associations" do
#     before do
#       Remotely.app :thingsapp,  "localhost:9999"
#     end
#
#     it "supports lambda :path argument and executes them on the model isntance" do
#       Truck.has_many_remote :things, :path => lambda { "/things/#{id}" }
#       conn.should_receive(:get).with("/things/2")
#       model.things
#     end
#   end
#
#   describe "has_many_remote" do
#     before do
#       Remotely.app :wheelapp,  "localhost:5432"
#       Truck.has_many_remote :wheels, :app => :wheelapp, :path => "/trucks/:id/wheels"
#     end
#
#     it "creates a method for each association" do
#       model.should respond_to :wheels
#     end
#
#     it "takes the :path option as precedence" do
#       Truck.has_many_remote :wheels, :path => "/grapes"
#       model.wheels
#       model.remote_associations[:wheels][:path].should == "/grapes"
#     end
#
#     it "supports :id substitution for :path once called" do
#       conn.should_receive(:get).with("/trucks/2/wheels")
#       model.wheels
#     end
#
#     it "accepts the app where the association is found" do
#       model.wheels
#       model.remote_associations[:wheels][:app].should == :wheelapp
#     end
#
#     it "requests the full url" do
#       conn.should_receive(:get).with("/trucks/2/wheels").and_return(resp)
#       model.wheels
#     end
#   end
#
#   describe "has_one_remote" do
#     before do
#       Remotely.app :engineapp, "localhost:9876"
#       Truck.has_one_remote :engine, :app => :engineapp
#     end
#
#     it "creates a method for each association" do
#       model.should respond_to :engine
#     end
#
#     it "accesses the association directly" do
#       resp.stub(:body) { "{\"size\":\"2.5L\",\"hp\":\"300\"}" }
#       model.engine.size.should == "2.5L"
#     end
#
#     it "supports :id substitution for :path once called" do
#       Truck.has_one_remote :engine, :app => :engineapp, :path => "/trucks/:id/engine"
#       conn.should_receive(:get).with("/trucks/2/engine")
#       model.engine
#     end
#
#     it "accepts the app where the association is found" do
#       model.engine
#       model.remote_associations[:engine][:app].should == :engineapp
#     end
#
#     it "requests the full url" do
#       conn.should_receive(:get).with("/trucks/2/engine").and_return(resp)
#       model.engine
#     end
#   end
#
#   describe "belongs_to_remote" do
#     before do
#       Remotely.app :ownerapp, "localhost:5555"
#       Truck.belongs_to_remote :owner, :app => :ownerapp, :path => "/owners/:owner_id"
#       model.owner_id = 4
#     end
#
#     it "creates a method for each association" do
#       model.should respond_to :owner
#     end
#
#     it "accesses the association directly" do
#       resp.stub(:body) { "{\"name\":\"Frank\"}" }
#       model.owner.name.should == "Frank"
#     end
#
#     it "supports :symbol substitution for :path once called" do
#       conn.should_receive(:get).with("/owners/4")
#       model.owner
#     end
#
#     it "accepts the app where the association is found" do
#       model.owner
#       model.remote_associations[:owner][:app].should == :ownerapp
#     end
#
#     it "requests the full url" do
#       conn.should_receive(:get).with("/owners/4").and_return(resp)
#       model.owner
#     end
#   end
#
#   describe "retreived objects" do
#     before do
#       Remotely.app :wheelapp,  "localhost:5432"
#       Truck.has_many_remote :wheels, :app => :wheelapp, :path => "/trucks/:id/wheels"
#       resp.stub(:body) { "[{\"size\":17,\"width\":10}]" }
#     end
#
#     it "is an array of objects" do
#       model.wheels.should respond_to(:each)
#     end
#
#     it "is an array of structs responding to the attributes returned" do
#       model.wheels[0].should respond_to(:size)
#     end
#
#     it "caches retreived objects and doesn't retreive them again" do
#       model.wheels
#       Remotely.connections[:wheelapp].should_not_receive(:get)
#       model.wheels
#     end
#
#     it "forces re-retreival with the bang method" do
#       model.wheels
#       Remotely.connections[:wheelapp].should_receive(:get)
#       model.wheels!
#     end
#
#     it "doesn't connect client-side associations until they are accessed" do
#       resp.stub(:body) { "[{\"user_id\":1}]" }
#       User.should_not_receive(:find)
#       model.wheels
#     end
#
#     it "connects associations on the client side when accessed" do
#       resp.stub(:body) { "[{\"user_id\":1}]" }
#       User.should_receive(:find).with(1)
#       model.wheels[0].user
#     end
#   end
# end
