$:.unshift(File.dirname(__FILE__))

require 'helpers/unit_test_helper'
require 'models/location'
require 'models/note'
require 'models/project'
require 'models/task'
require 'models/user'


class ToFxmlTest < Test::Unit::TestCase
  fixtures :locations, :notes, :projects, :tasks, :users
  
  def test_to_fxml_sanity
    assert_nothing_raised {users(:ludwig).to_fxml}
  end
  
  def test_to_fxml_doesnt_dasherize
    set_response_to users(:ludwig).to_fxml
    assert_xml_select 'user first_name', 'Ludwig'    
  end
  
  def test_to_fxml_with_single_include
    set_response_to users(:ludwig).to_fxml(:include => [:locations])
    assert_xml_select 'user locations location name', 'Vienna'
  end
  
  def test_to_fxml_with_double_nested_include
    set_response_to users(:ludwig).to_fxml(:include => {:locations => {:include => :tasks}})
    assert_xml_select 'user locations location tasks name', 'Get piano lessons from Haydn'
  end
  
end