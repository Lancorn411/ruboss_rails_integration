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
  
  def test_default_xml_methods_on_user_are_included_in_fxml
    set_response_to users(:ludwig).to_fxml
    assert_xml_select 'user full_name', 'Ludwig van Beethoven'
    assert_xml_select 'user has_nothing_to_do'
  end

  def test_default_xml_methods_on_user_are_included_in_fxml_if_you_call_it_twice
    set_response_to users(:ludwig).to_fxml
    set_response_to users(:ludwig).to_fxml
    assert_xml_select 'user full_name', 'Ludwig van Beethoven'
    assert_xml_select 'user has_nothing_to_do'
  end

  
  def test_default_xml_methods_on_task_are_included_in_fxml
    set_response_to tasks(:learn_piano).to_fxml
    assert_xml_select 'task is_active'
  end
  
  def test_default_xml_methods_exists
    assert User.respond_to?(:default_xml_methods_a)
    assert_equal [:full_name, :has_nothing_to_do], User.default_xml_methods_a
  end
  
  def test_default_xml_methods_on_dependencies
    t = users(:ludwig).tasks.first
    assert t.class.respond_to?(:default_xml_methods_a)
    assert_equal [:is_active], t.class.default_xml_methods_a
  end
  
  def test_default_xml_methods_are_included_in_includes
    set_response_to users(:ludwig).to_fxml(:include => :tasks)
    puts @response.body
    assert_xml_select 'tasks task is_active'
  end
  
  def test_model_without_default_xml_methods_still_works
    assert_nothing_raised{ locations(:vienna).to_fxml }
  end
  
  # Test type=.... stuff for has_many, booleans, integers, dates, date-times
  
end