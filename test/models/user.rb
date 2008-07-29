class User < ActiveRecord::Base
  has_one :note
  has_many :tasks
  has_many :projects
  has_many :locations
  
  default_fxml_methods [:full_name]
  
  def full_name
    "#{first_name} #{last_name}"
  end
end
