class User < ActiveRecord::Base
  has_one :note
  has_many :tasks
  has_many :projects
  has_many :locations
end
