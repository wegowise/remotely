require File.dirname(__FILE__) + '/../spec_helper'

describe Remotely::Model do
  let(:app)        { "http://localhost:1234" }
  let(:attributes) { {id: 1, name: "Marceline Quest", type: "MATHEMATICAL!"} }

  subject { Adventure.new(attributes) }

  describe ".attr_savable" do
    let(:attrs) { {id: 2, name: "Wishes!", type: "MATHEMATICAL!", length: 9} }
    let(:saved) { to_json({name: "OMG New Name!", type: "MATHEMATICAL!", id: 2}) }

    subject { Adventure.new(attrs) }

    it "stores which attributes are savable" do
      Adventure.savable_attributes.should == [:name, :type]
    end

    it "only sends the specified attributes when saving an existing record" do
      stub_request(:put, "#{app}/adventures/2").to_return(body: saved)
      subject.update_attribute(:name, "OMG New Name!")
      a_request(:put, "#{app}/adventures/2").with(body: saved).should have_been_made
    end
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
    let(:attrs) { attributes.except(:id) }

    before do
      stub_request(:post, "#{app}/adventures").to_return(lambda { |req| { body: req.body, status: 201 }})
    end

    it "creates the resource" do
      Adventure.create(attrs)
      a_request(:post, "#{app}/adventures").with(attrs).should have_been_made
    end

    it "returns the new resource on creation" do
      Adventure.create(attrs).name.should == "Marceline Quest"
    end

    it "returns false when the creation fails" do
      stub_request(:post, %r[/adventures]).to_return(status: 500)
      Adventure.create(attrs).should be_false
    end
  end

  describe ".find_or_" do
    let(:body)         { Yajl::Encoder.encode([{id: 1, name: "BubbleGum"}]) }
    let(:stub_success) { stub_request(:get, "#{app}/adventures/search?name=BubbleGum").to_return(body: body) }
    let(:stub_failure) { stub_request(:get, "#{app}/adventures/search?name=BubbleGum").to_return(body: "[]") }

    describe "initialize" do
      it "tries to fetch the record" do
        stub_success
        Adventure.find_or_initialize(name: "BubbleGum")
        a_request(:get, "#{app}/adventures/search?name=BubbleGum").should have_been_made
      end

      it "returns the fetched object if found" do
        stub_success
        Adventure.find_or_initialize(name: "BubbleGum").id.should == 1
      end

      it "creates a new object if one is not found" do
        stub_failure
        Adventure.find_or_initialize(name: "BubbleGum").should be_a_new_record
      end
    end

    describe "create" do
      it "automatically saves the new object" do
        stub_failure
        Adventure.should_receive(:create).with(name: "BubbleGum")
        Adventure.find_or_create(name: "BubbleGum")
      end

      it "returns the first item from the collection" do
        stub_success
        Adventure.find_or_create(name: "BubbleGum").should be_an Adventure
      end
    end
  end

  describe ".find_by_*" do
    it "searches by a single attribute" do
      Adventure.find_by_name("Fun")
      a_request(:get, "#{app}/adventures/search?name=Fun").should have_been_made
    end

    it "searches by multiple attributes seperated by 'and'" do
      Adventure.find_by_name_and_type("Fun", "MATHEMATICAL!")
      a_request(:get, "#{app}/adventures/search?name=Fun&type=MATHEMATICAL!").should have_been_made
    end
  end

  describe ".all" do
    it "fetches all resources" do
      Adventure.all
      a_request(:get, "#{app}/adventures").should have_been_made
    end
  end

  describe ".update_all" do
    it "request an update to all entries" do
      Adventure.update_all(type: "awesome")
      a_request(:put, "#{app}/adventures").with(type: "awesome").should have_been_made
    end
  end

  describe "#save" do
    let(:new_name)       { "City of Thieves" }
    let(:new_attributes) { attributes.merge(name: new_name) }

    context "when updating" do
      it "updates the resource" do
        adventure = Adventure.new(attributes)
        adventure.name = new_name
        adventure.save
        a_request(:put, "#{app}/adventures/1").with(new_attributes).should have_been_made
      end

      it "returns true when the save succeeds" do
        Adventure.new(attributes).save.should be_a Adventure
      end

      it "returns false when the save fails" do
        adventure = Adventure.new(attributes)
        stub_request(:put, %r[/adventures/1]).to_return(status: 409, body: to_json({errors: {base: %w{this failed}}}))
        adventure.save.should == false
      end

      it "sets errors when a save fails" do
        adventure = Adventure.new(attributes)
        stub_request(:put, %r[/adventures/1]).to_return(status: 409, body: to_json({errors: {base: %w{this failed}}}))
        adventure.save
        adventure.errors[:base].should == %w{this failed}
      end
    end

    context "when creating" do
      it "merges in the response body to attributes on success" do
        adventure = Adventure.new(name: "To Be Saved...")
        stub_request(:post, %r(/adventures)).to_return(body: to_json(attributes.merge(name: "To Be Saved...", id: 2)), status: 201)
        adventure.save
        adventure.id.should == 2
      end

      it "returns false on failure" do
        stub_request(:post, %r(/adventures)).to_return(status: 409)
        Adventure.new(name: "name").save.should == false
      end
    end
  end

  describe "#update_attribute" do
    it "updates a single attribute and saves" do
      subject.update_attribute(:type, "powerful")
      a_request(:put, "#{app}/adventures/1").with(type: "powerful").should have_been_made
    end
  end

  describe "#to_param" do
    it "returns correct value" do
      subject.to_param.should == '1'
    end
  end

  describe "#update_attributes" do
    let(:updates)        { {type: "awesome"} }
    let(:new_attributes) { subject.attributes.merge(updates) }

    it "replaces existing attribute values" do
      subject.update_attributes(updates)
      subject.type.should == "awesome"
    end

    it "calls save" do
      subject.update_attributes(updates)
      a_request(:put, "#{app}/adventures/1").with(new_attributes).should have_been_made
    end

    it "returns true on success" do
      subject.update_attributes(updates).should be_true
    end

    it "returns false on failure" do
      stub_request(:put, %r[/adventures/1]).to_return(status: 500)
      subject.update_attributes(updates).should be_false
    end

    it "reverts the object's attributes if the save fails" do
      stub_request(:put, %r[/adventures/1]).to_return(status: 500)
      subject.update_attributes(updates)
      subject.type.should == "MATHEMATICAL!"
    end
  end

  describe "#destroy" do
    it "destroys a resource with the might of 60 jotun!!" do
      Adventure.new(attributes).destroy
      a_request(:delete, "#{app}/adventures/1").should have_been_made
    end
  end

  describe "associations" do
    let(:member) { Member.new(id: 2, name_id: 1) }

    it "creates associations when instantiated" do
      member.should respond_to :name
    end

    it "fetches the resource when accessed" do
      Name.should_receive(:find).with(1)
      member.name
    end

    it "doesn't fetch a resource twice" do
      Name.should_receive(:find).with(1).once
      member.name
      member.name
    end

    it "reloads association objects" do
      Name.should_receive(:find).with(1).twice
      member.name
      member.name(true)
    end
  end

  it "sets the app it belongs to" do
    Adventure.app.should == :adventure_app
  end

  it "sets the uri to itself" do
    Adventure.uri.should == "/adventures"
  end

  it "has a connection" do
    Adventure.remotely_connection.should be_a Faraday::Connection
  end

  it "supports ActiveModel::Naming methods" do
    Adventure.model_name.element.should == "adventure"
  end

  it "is reloadable" do
    subject.reload
    a_request(:get, "#{app}/adventures/1")
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

  it "creates boolean methods for each attribute" do
    subject.name?.should == true
  end

  it "returns id from #to_key" do
    subject.id = 1
    subject.to_key.should == [1]
  end

  it "returns id from #to_param" do
    subject.id = 1
    subject.to_param.should == "1"
  end

  it "returns itself from #to_model" do
    subject.to_model.should == subject
  end

  context "with errors" do
    let(:attributes) { {'errors' => {:base => %w{totally failed dude}}} }

    it "adds errors during #initialize" do
      subject.errors[:base].should == %w{totally failed dude}
    end
  end
end
