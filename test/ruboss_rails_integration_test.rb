require 'test/unit'
require 'rubygems'
require 'action_controller'
require 'active_support'
require 'active_record'
require File.join(File.dirname(__FILE__), '..', 'lib', 'ruboss_rails_integration')
# require File.join(File.dirname(__FILE__), '..', 'init')

class RubossRailsIntegrationTest < Test::Unit::TestCase

  def test_to_fxml_with_args_on_empty_array_should_not_blow_up
    a = ArrayWithClassyToXml.new(Object)
    assert_nothing_raised {a.to_fxml}
    assert_nothing_raised {a.to_fxml(:include => :test)}
  end

end
