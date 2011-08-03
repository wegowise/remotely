require File.dirname(__FILE__) + '/../spec_helper'

describe Remotely::Model do
  class Adventure < Remotely::Model
    app :adventure_app
    uri "/adventures"
  end

  let(:app)        { "http://localhost:5555" }
  let(:attributes) { {id: 1, name: "Marceline Quest", type: "MATHEMATICAL!", user_id: 2} }

  subject   { Adventure.new(attributes) }

  before do
    Remotely.app :adventure_app, app
  end

  describe ".find" do
    it "retreives an individual resource" do
      Adventure.find(1)
      a_request(:get, "#{app}/adventures/1").should have_been_made
    end
  end

  describe ".where" do
    it "searches for resources" do
      Adventure.where(:type => "MATHEMATICAL!")
      a_request(:get, "#{app}/adventures/search?type=MATHEMATICAL!").should have_been_made
    end

    it "returns a collection of resources" do
      Adventure.where(:type => "MATHEMATICAL!").should be_a Remotely::Collection
    end
  end

  describe ".destroy" do
    it "destroys the resource" do
      Adventure.destroy(1)
      a_request(:delete, "#{app}/adventures/1").should have_been_made
    end

    it "returns true on success" do
      Adventure.destroy(1).should be_true
    end

    it "returns false on failure" do
      stub_request(:delete, %r[/adventures/1]).to_return(status: 500)
      Adventure.destroy(1).should be_false
    end
  end

  describe ".create" do
    it "creates the resource" do
      Adventure.create(attributes)
      a_request(:post, "#{app}/adventures").with(attributes).should have_been_made
    end

    it "returns the new resource on creation" do
      Adventure.create(attributes).name.should == "Marceline Quest"
    end

    it "returns false when the creation fails" do
      stub_request(:post, %r[/adventures]).to_return(status: 500)
      Adventure.create(attributes).should be_false
    end
  end

  describe ".save" do
    it "saves a resource using id and attributes" do
      Adventure.save(1, name: "Fun")
      a_request(:put, "#{app}/adventures/1").with(attributes).should have_been_made
    end
  end

  describe "#save" do
    let(:new_name)       { "City of Thieves" }
    let(:new_attributes) { attributes.merge(name: new_name) }

    it "updates the resource" do
      adventure = Adventure.new(attributes)
      adventure.name = new_name
      adventure.save
      a_request(:put, "#{app}/adventures/1").with(new_attributes).should have_been_made
    end

    it "returns true when the save succeeds" do
      Adventure.new(attributes).save.should == true
    end
  end

  describe "#destroy" do
    it "destroys a resource with the might of 60 jotun!!" do
      Adventure.new(attributes).destroy
      a_request(:delete, "#{app}/adventures/1").should have_been_made
    end
  end

  it "sets the app it belongs to" do
    Adventure.app.should == :adventure_app
  end

  it "sets the uri to itself" do
    Adventure.uri.should == "/adventures"
  end

  it "has a connection" do
    Adventure.connection.should be_a Faraday::Connection
  end

  it "supports ActiveModel::Naming methods" do
    Adventure.model_name.should == "Adventure"
  end

  it "symbolizes attribute keys" do
    subject.attributes.should == attributes
  end

  it "can be initialized with a hash of attribute/values" do
    subject.name.should == "Marceline Quest"
  end

  it "sets an attribute value" do
    subject.name = "City of Thieves"
    subject.name.should == "City of Thieves"
  end

  it "raises a normal NoMethodError for non-existent attributes" do
    expect { subject.height }.to raise_error(NoMethodError)
  end

  it "is a new_record when no id exists" do
    subject.id = nil
    subject.should be_a_new_record
  end

  it "creates association methods" do
    subject.should respond_to(:user)
  end

  it "finds the association when accessed" do
    User.should_receive(:find).with(2)
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
