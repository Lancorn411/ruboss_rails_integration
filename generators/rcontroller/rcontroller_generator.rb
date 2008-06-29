################################################################################
# Copyright 2008, Ruboss Technology Corporation.
#
# This software is dual-licensed under both the terms of the Ruboss Commercial
# License as published by Ruboss Technology Corporation and under the terms of
# the GNU General Public License v3 (GPL v3) as published by the Free Software
# Foundation.
#
# Your use of the software is governed by the terms specified in the
# LICENSE.txt file included with the source code. This file will either contain
# the Ruboss Commercial License or the GPL v3, depending on whether you
# are using the commercial version or the GPL v3 version of the software.
# To learn more or to buy a commercial license, please go to http://ruboss.com.
################################################################################
class RcontrollerGenerator < Rails::Generator::Base
  include Ruboss::Configuration
  
  attr_reader :project_name, 
              :flex_project_name, 
              :base_package, 
              :base_folder, 
              :command_controller_name,
              :model_names, 
              :command_names

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
    end
  end

  protected
    def banner
      "Usage: #{$0} #{spec.name}" 
    end
end
