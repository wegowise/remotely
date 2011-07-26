require File.dirname(__FILE__) + '/../spec_helper'

describe Remotely::Model do
  subject { Remotely::Model.new(:name => "Fred", :user_id => 1) }

  it "symbolizes keys" do
    Remotely::Model.new("name" => "Fred").attributes.should == {:name => "Fred"}
  end

  it "can be initialized with a hash of attribute/values" do
    subject.name.should == "Fred"
  end

  it "raises a normal NoMethodError for non-existent attributes" do
    -> { subject.height }.should raise_error(NoMethodError)
  end

  it "creates association methods" do
    subject.should respond_to(:user)
  end

  it "finds the association when accessed" do
    User.should_receive(:find).with(1)
    subject.user
  end

  it "does not find the association when created" do
    User.should_not_receive(:find)
    subject
  end

  it "creates boolean methods for each attribute" do
    subject.name?.should == true
  end
end
