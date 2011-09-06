require "ostruct"

Remotely.app :adventure_app, "http://localhost:1234"

class BaseTestClass < OpenStruct
  extend  ActiveModel::Naming
  include Remotely::Associations
  def self.base_class; self; end
end

# has_many

class HasMany < BaseTestClass
  has_many_remote :things
end

class HasManyWithPath < BaseTestClass
  has_many_remote :things, :path => "/custom/things"
end

class HasManyWithPathVariables < BaseTestClass
  has_many_remote :things, :path => "/custom/:name/things/"
end

class HasManyWithForeignKey < BaseTestClass
  has_many_remote :things, :foreign_key => :fkey
end

# has_one

class HasOne < BaseTestClass
  has_one_remote :thing
end

class HasOneWithPath < BaseTestClass
  has_one_remote :thing, :path => "/custom/thing"
end

class HasOneWithPathVariables < BaseTestClass
  has_one_remote :thing, :path => "/custom/:name/thing"
end

class HasOneWithForeignKey < BaseTestClass
  has_one_remote :thing, :foreign_key => :fkey
end

# belongs_to

class BelongsTo < BaseTestClass
  belongs_to_remote :thing
end

class BelongsToWithPath < BaseTestClass
  belongs_to_remote :thing, :path => "/custom/thing"
end

class BelongsToWithPathVariables < BaseTestClass
  belongs_to_remote :thing, :path => "/custom/:name/thing"
end

class BelongsToWithForeignKey < BaseTestClass
  belongs_to_remote :thing, :foreign_key => :fkey
end

# Generic

class Thing < Remotely::Model
end

class Adventure < Remotely::Model
  app :adventure_app
  uri "/adventures"
  has_many_remote :members
  attr_savable :name, :type
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
