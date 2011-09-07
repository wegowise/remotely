require File.dirname(__FILE__) + '/../spec_helper'

describe Remotely::Collection do
  let(:finn)      { Member.new(id: 1, name: "Finn", type: "human") }
  let(:jake)      { Member.new(id: 2, name: "Jake", type: "dog")   }
  let(:adventure) { Adventure.new(id: 3) }

  subject { Remotely::Collection.new(adventure, Member, [jake, finn]) }

  describe "#find" do
    it "finds by id" do
      subject.find(1).should == finn
    end
  end

  describe "#where" do
    it "is searchable by attributes and values" do
      subject.where(name: "Jake", type: "dog").should == [jake]
    end

    it "returns a new Collection" do
      subject.where(name: "Jake", type: "dog").should be_a Remotely::Collection
    end
  end

  describe "#order" do
    it "orders by an attribute" do
      subject.order(:name).should == [finn, jake]
    end
  end

  describe "#build" do
    it "creates a new model object with the foreign key automatically defined" do
      adventure.members.build.adventure_id.should == 3
    end

    it "adds the new object to itself" do
      new_member = adventure.members.build
      adventure.members.should include(new_member)
    end
  end

  describe "#create" do
    before do
      stub_request(:post, %r(/members)).to_return(lambda { |req| {body: req.body} })
    end

    it "creates and saves a new model object with the foreign key automatically defined" do
      adventure.members.create.adventure_id.should == 3
    end

    it "adds the new object to itself" do
      new_member = adventure.members.create
      adventure.members.should include(new_member)
    end
  end
end
