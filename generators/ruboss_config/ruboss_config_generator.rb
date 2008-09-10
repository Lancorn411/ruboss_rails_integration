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
require 'open-uri'

class RubossConfigGenerator < Rails::Generator::Base
  include Ruboss::Configuration
    
  attr_reader :project_name, 
              :flex_project_name, 
              :base_package, 
              :base_folder, 
              :command_controller_name, 
              :component_names, 
              :application_tag,
              :use_air
              # added for Events.as class
              :model_names

  def initialize(runtime_args, runtime_options = {})
    super
    @project_name, @flex_project_name, @command_controller_name, @base_package, @base_folder = extract_names
    
    # if we updating main file only we probably want to maintain the type of project it is
    if options[:app_only]
      project_file_name = ::RAILS_ROOT + '/.project'
      if File.exist?(project_file_name)
        puts "Cannot combine -m (--main-app) and -a (--air) flags at the same time for an existing application.\n" << 
          'If you want to convert to AIR, remove -m flag.' if options[:air_config]
        @use_air = true if File.read(project_file_name) =~/com.adobe.flexbuilder.apollo.apollobuilder/m
      else
        puts "Flex Builder project file doesn't exist. You should run 'rconfig' with -a (--air) or no arguments " <<
          "first to generate primary project structure."
        exit 0;
      end
    else
      @use_air = options[:air_config]
    end
                
    if @use_air
      @application_tag = 'WindowedApplication'
    else
      @application_tag = 'Application'
    end
        
    @component_names = []
    if File.exists?("app/flex/#{base_folder}/components/generated")
      @component_names = list_mxml_files("app/flex/#{base_folder}/components/generated")
    end
  end

  def manifest
    record do |m|
      if !options[:app_only]
        m.file 'flex.properties', '.flexProperties'
  
        m.directory 'html-template/history'      
        %w(index.template.html AC_OETags.js playerProductInstall.swf).each do |file|
          m.file "html-template/#{file}", "html-template/#{file}"
        end
        
        %w(history.css history.js historyFrame.html).each do |file|
          m.file "html-template/history/#{file}", "html-template/history/#{file}"
        end
        
        %w(components controllers commands models events).each do |dir|
          m.directory "app/flex/#{base_folder}/#{dir}"
        end
        
        m.directory "app/flex/#{base_folder}/components/generated"
        
        # If you specify using Cairngorm Architecture, import these main classes:
        # AppController.as < FrontController, ModelLocator.as < ModelLocator, Events.as
        if options[:cairngorm]
          if @use_air
            m.template 'cairngorm/actionscriptair.properties', '.actionScriptProperties'
            m.template 'cairngorm/projectair.properties', '.project'
          else
            m.template 'cairngorm/actionscript.properties', '.actionScriptProperties'
            m.template 'cairngorm/project.properties', '.project'
          end
          
          # Add Cairngorm.SWC to path
          m.directory "app/flex/lib"
          m.file 'cairngorm/Cairngorm.swc', 'app/flex/lib/Cairngorm.swc'
          
          # Create directories for Cairngorm classes...
          m.directory "app/flex/#{base_folder}/components/generated/users"
          m.directory "app/flex/#{base_folder}/commands"
          
          # Create assets directory for images...
          m.directory "app/flex/assets/images"
          m.file 'cairngorm/cairngorm.gif', 'app/flex/assets/images/cairngorm.gif'
          
          # Add CairngormUtils for Event Dispatching
          m.directory "app/flex/com/pomodo/utils"
          m.file 'cairngorm/CairngormUtils.as', 'app/flex/com/pomodo/utils/CairngormUtils.as'

          # Add AppController and AppEvents to the project
          m.template 'cairngorm/app_controller.as.erb',
            File.join("app", "flex", base_folder, "controllers", "AppController.as")

          # Add the Model Locator, which holds only application states
          m.template 'cairngorm/model_locator.as.erb',
            File.join("app", "flex", base_folder, "models", "#{project_name}ModelLocator.as")

          # Add the main Events class, which holds a list of all Event Types
          m.template 'cairngorm/events.as.erb', File.join("app", "flex", base_folder, "controllers", "#{project_name}Events.as")
          
          # Main Application file.  Each application starts with a 1) Account Screen and 2) Main Screen
          m.template 'cairngorm/main_box.mxml.erb', File.join('app/flex', base_folder, 'components/generated/users', "MainBox.mxml")

          m.template 'cairngorm/mainapp.mxml', File.join('app/flex', "#{project_name}.mxml")
          m.template 'cairngorm/mainair-app.xml', File.join('app/flex', "#{project_name}-app.xml") if @use_air
        else
          if @use_air
            m.template 'actionscriptair.properties', '.actionScriptProperties'
            m.template 'projectair.properties', '.project'
          else
            m.template 'actionscript.properties', '.actionScriptProperties'
            m.template 'project.properties', '.project'
          end
        end
        
        # The new RubossCommandsClass causes everything to not work...
        # Ruboss Framework
        # framework_distribution_url = "http://ruboss.com/releases/ruboss-#{FRAMEWORK_RELEASE}.swc"
        # framework_destination_file = "lib/ruboss-#{FRAMEWORK_RELEASE}.swc"
        
        # if !options[:skip_framework] && !File.exist?(framework_destination_file)
        #   puts "fetching #{FRAMEWORK_RELEASE} framework binary from: #{framework_distribution_url} ..."
        #   open(framework_destination_file, "wb").write(open(framework_distribution_url).read)
        #   puts "done. saved to #{framework_destination_file}"
        # end
        
        m.file 'ruboss.swc', 'lib/ruboss.swc'
  
        m.file 'swfobject.js', 'public/javascripts/swfobject.js'
        m.file 'expressInstall.swf', 'public/expressInstall.swf'
        m.template 'index.html.erb', 'public/index.html'
        
        m.dependency 'ruboss_controller', @args
      end
      
      unless options[:cairngorm]
        m.template 'mainapp.mxml', File.join('app/flex', "#{project_name}.mxml")
        m.template 'mainair-app.xml', File.join('app/flex', "#{project_name}-app.xml") if @use_air
      end
    end
  end

  protected
    # These two methods, model_names and list_as_files, are used to
    # create the Events.as class properly
    def model_names
      @model_names = []
      if File.exists?("app/flex/#{base_folder}/models")
        @model_names = list_as_files("app/flex/#{base_folder}/models")
      end
    end
    
    def list_as_files(dir_name)
      Dir.entries(dir_name).grep(/\.as$/).map { |name| name.sub(/\.as$/, "") }
    end
    
    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("-m", "--app-only", "Only generate the main Flex/AIR application file.", 
        "Default: false") { |v| options[:app_only] = v }
      opt.on("-a", "--air", "Configure AIR project instead of Flex. Flex is default.", 
        "Default: false") { |v| options[:air_config] = v }
      opt.on("-s", "--skip-framework", "Don't fetch the latest framework binary. You'll have to link/build the framework yourself.", 
        "Default: false") { |v| options[:skip_framework] = v }
      opt.on("-c", "--cairngorm", "Wire up your Flexible Rails application using the Cairngorm Framework.", 
        "Default: false") { |v| options[:cairngorm] = v }
    end

    def banner
      "Usage: #{$0} #{spec.name}" 
    end
end