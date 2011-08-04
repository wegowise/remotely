require "ostruct"

Remotely.app :adventure_app, "http://localhost:1234"

class Adventure < Remotely::Model
  app :adventure_app
  uri "/adventures"
  has_many_remote :members
end

class CustomAdventure < OpenStruct
  extend  ActiveModel::Naming
  include Remotely::Associations
  has_many_remote :members, :path => "/custom/members"
end

class Member < Remotely::Model
  app :adventure_app
  uri "/members"
  belongs_to_remote :adventure
  has_one_remote    :weapon
end

class CustomMember < OpenStruct
  extend ActiveModel::Naming
  include Remotely::Associations
  belongs_to_remote :adventure, :path => "/custom/:name/adventures"
end

class Weapon < Remotely::Model
  app :adventure_app
  uri "/weapons"
end

class Name
  def self.find(id); end
end
