require "spec_helper"

describe Remotely::Associations do
  let(:app) { "http://localhost:1234" }

  shared_examples_for "an association" do
    it "keeps track of it's remote associations" do
      subject.remote_associations.should include(assoc)
    end

    it "creates a method for the association" do
      subject.should respond_to(assoc)
    end

    it "creates a setter for the associations" do
      subject.public_send(:"#{assoc}=", "guy")
      subject.public_send(assoc).should == "guy"
    end
  end

  shared_examples_for "an association with a path" do
    it "generates the correct path" do
      subject.path_to(assoc, type).should == path
    end

    it "requests the correct path" do
      subject.send(assoc)
      a_request(:get, "#{app}#{path}").should have_been_made
    end
  end

  describe "has_many_remote" do
    subject     { HasMany.new(id: 1) }
    let(:type)  { :has_many }
    let(:assoc) { :things }

    it_behaves_like "an association"

    it "returns a Collection" do
      subject.things.should be_a Remotely::Collection
    end

    it "returns a Collection of the appropriate model" do
      subject.things.first.should be_a Thing
    end

    context "with no options" do
      subject    { HasMany.new(id: 1) }
      let(:path) { "/has_manies/1/things" }
      it_behaves_like "an association with a path"
    end

    context "with the :path option" do
      subject    { HasManyWithPath.new(id: 1) }
      let(:path) { "/custom/things" }
      it_behaves_like "an association with a path"
    end

    context "with :path variables" do
      subject    { HasManyWithPathVariables.new(name: "stuff") }
      let(:path) { "/custom/stuff/things" }
      it_behaves_like "an association with a path"
    end

    context "with the :foreign_key option" do
      subject { HasManyWithForeignKey.new }
      specify { expect { subject.path_to(:things, :has_many) }.to raise_error(Remotely::HasManyForeignKeyError) }
    end
  end

  describe "has_one_remote" do
    subject     { HasOne.new(id: 1) }
    let(:type)  { :has_one }
    let(:assoc) { :thing }

    it_behaves_like "an association"

    it "returns an object of the appropriate model" do
      subject.thing.should be_a Thing
    end

    context "with no options" do
      subject    { HasOne.new(id: 1) }
      let(:path) { "/has_ones/1/thing" }
      it_behaves_like "an association with a path"
    end

    context "with the :path option" do
      subject    { HasOneWithPath.new(id: 1) }
      let(:path) { "/custom/thing" }
      it_behaves_like "an association with a path"
    end

    context "with :path variables" do
      subject    { HasOneWithPathVariables.new(name: "stuff") }
      let(:path) { "/custom/stuff/thing" }
      it_behaves_like "an association with a path"
    end

    context "with the :foreign_key option" do
      subject { HasOneWithForeignKey.new }
      specify { expect { subject.path_to(:thing, :has_one) }.to raise_error(Remotely::HasManyForeignKeyError) }
    end
  end

  describe "belongs_to_remote" do
    subject     { BelongsTo.new(id: 1, thing_id: 1) }
    let(:type)  { :belongs_to }
    let(:assoc) { :thing }

    it_behaves_like "an association"

    it "returns an object of the appropriate model" do
      subject.thing.should be_a Thing
    end

    context "with no options" do
      subject    { BelongsTo.new(thing_id: 1) }
      let(:path) { "/things/1" }
      it_behaves_like "an association with a path"
    end

    context "with the :path option" do
      subject    { BelongsToWithPath.new }
      let(:path) { "/custom/thing" }
      it_behaves_like "an association with a path"
    end

    context "with :path variables" do
      subject    { BelongsToWithPathVariables.new(name: "stuff") }
      let(:path) { "/custom/stuff/thing" }
      it_behaves_like "an association with a path"
    end
  end
end
