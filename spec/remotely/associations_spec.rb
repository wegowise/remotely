require "spec_helper"

describe Remotely::Associations do
  let(:app) { "http://localhost:1234" }

  describe "association definitions" do
    let(:adventure) { CustomAdventure.new(id: 1) }
    let(:member)    { CustomMember.new(id: 1, adventure_id: 1, name: "steve", fkey: "key") }

    it "accept a :path option for custom has_many associations" do
      adventure.path_to(:members, :has_many).should == "/custom_adventures/1/custom/members"
    end

    it "accept a :path option for custom has_one associations" do
      adventure.path_to(:members, :has_one).should == "/custom_adventures/1/custom/members"
    end

    it "accept a :path option for custom belongs_to associations" do
      member.path_to(:adventure, :belongs_to).should == "/custom/steve/adventures/1"
    end

    it "accepts a :foreign_key option" do
      member.remote_associations[:adventure][:foreign_key] = :fkey
      member.path_to(:adventure, :belongs_to).should == "/custom/steve/adventures/key"
      member.remote_associations[:adventure][:foreign_key] = nil
    end

    it "replaces symbols in :path with their corresponding attribute" do
      member.path_to(:adventure, :belongs_to).should == "/custom/steve/adventures/1"
    end
  end

  describe "has_many_remote" do
    let(:adventure) { Adventure.new(id: 1) }

    it "keeps track of it's remote associations" do
      Adventure.remote_associations.should include(:members)
    end

    it "generates the path to a has_many association" do
      adventure.path_to(:members, :has_many).should == "/adventures/1/members"
    end

    it "creates a method for the association" do
      adventure.should respond_to(:members)
    end

    it "requests the correct path when accessed" do
      adventure.members
      a_request(:get, "#{app}/adventures/1/members").should have_been_made
    end

    it "returns a Collection" do
      adventure.members.should be_a Remotely::Collection
    end

    it "returns a Collection of the appropriate model" do
      adventure.members.first.should be_a Member
    end
  end

  describe "belongs_to_remote" do
    let(:member) { Member.new(id: 2, adventure_id: 1) }

    it "generates the path to a belongs_to association" do
      member.path_to(:adventure, :belongs_to).should == "/adventures/1"
    end

    it "creates a method for the association" do
      member.should respond_to(:adventure)
    end

    it "requests the correct path when accessed" do
      member.adventure
      a_request(:get, "#{app}/adventures/1").should have_been_made
    end

    it "returns an object of the appropriate model class" do
      member.adventure.should be_a Adventure
    end
  end

  describe "has_one_remote" do
    let(:member) { Member.new(id: 3) }

    it "generates the path to a belongs_to association" do
      member.path_to(:weapon, :has_one).should == "/members/3/weapons"
    end

    it "creates a method for the association" do
      member.should respond_to(:weapon)
    end

    it "requests the correct path when accessed" do
      member.weapon
      a_request(:get, "#{app}/members/3/weapons").should have_been_made
    end

    it "returns an object of the appropriate model class" do
      member.weapon.should be_a Weapon
    end
  end
end
