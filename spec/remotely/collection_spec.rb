require File.dirname(__FILE__) + '/../spec_helper'

describe Remotely::Collection do
  let(:finn) { Remotely::Model.new(id: 1, name: "Finn", type: "human") }
  let(:jake) { Remotely::Model.new(id: 2, name: "Jake", type: "dog")   }

  subject { Remotely::Collection.new([finn, jake]) }

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
end
