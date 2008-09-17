################################################################################
# Copyright 2008, Ruboss Technology Corporation.
#
# This software is dual-licensed under both the terms of the Ruboss Commercial
# License v1 (RCL v1) as published by Ruboss Technology Corporation and under
# the terms of the GNU General Public License v3 (GPL v3) as published by the
# Free Software Foundation.
#
# Both the RCL v1 (rcl-1.0.txt) and the GPL v3 (gpl-3.0.txt) are included in
# the source code. If you have purchased a commercial license then only the
# RCL v1 applies; otherwise, only the GPL v3 applies. To learn more or to buy a
# commercial license, please go to http://ruboss.com.
################################################################################
class RubossControllerGenerator < Rails::Generator::Base
  include Ruboss::Configuration
  
  attr_reader :project_name, 
              :flex_project_name, 
              :base_package, 
              :base_folder, 
              :command_controller_name,
              :model_names, 
              :command_names,
              :event_names

  def initialize(runtime_args, runtime_options = {})
    super
    @project_name, @flex_project_name, @command_controller_name, @base_package, @base_folder = extract_names
    
    @model_names = list_as_files("app/flex/#{base_folder}/models")
    @command_names = list_as_files("app/flex/#{base_folder}/commands")
  end

  def manifest
    record do |m|      
      m.template 'controller.as.erb', File.join("app/flex/#{base_folder}/controllers", 
        "#{command_controller_name}.as")
      m.template 'events.as.erb', File.join("app/flex/#{base_folder}/controllers", 
        "#{project_name}Event.as")
      m.template 'model_locator.as.erb', File.join("app/flex/#{base_folder}/models", 
        "#{project_name}ModelLocator.as")
    end
  end

  protected
    # These two methods, model_names and list_as_files, are used to
    # create the Events.as class properly
    def event_names
      @event_names = []
      if File.exists?("app/flex/#{base_folder}/models")
        @event_names = list_as_files_for_events("app/flex/#{base_folder}/models")
      end
    end
    
    def list_as_files_for_events(dir_name)
      Dir.entries(dir_name).grep(/\.as$/).map { |name| name.sub(/\.as$/, "") }
    end
    
    def banner
      "Usage: #{$0} #{spec.name}" 
    end
end
