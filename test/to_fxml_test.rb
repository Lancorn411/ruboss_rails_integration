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
  
  def test_default_fxml_methods_on_user_are_included_in_fxml
    set_response_to users(:ludwig).to_fxml
    assert_xml_select 'user full_name', 'Ludwig van Beethoven'
  end
  
  def test_model_without_default_fxml_methods_still_works
    assert_nothing_raised{ tasks(:learn_piano).to_fxml }
  end
  
end