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
module Rails
  module Generator
    class GeneratedAttribute
      attr_accessor :name, :type, :column, :flex_name, :model_type # added model_type back for DataGrid Component...

      def initialize(name, type)
        @name, @type = name, type.to_sym
        @flex_name = name.camelcase(:lower)
        @column = ActiveRecord::ConnectionAdapters::Column.new(name, nil, @type)
      end

      def field_type
        @field_type ||= case type
          when :integer, :float, :decimal   then :text_field
          when :datetime, :timestamp, :time then :datetime_select
          when :date                        then :date_select
          when :string                      then :text_field
          when :text                        then :text_area
          when :boolean                     then :check_box
          else
            :text_field
        end      
      end

      def default(prefix = '')
        @default = case type
          when :integer                     then 1
          when :float                       then 1.5
          when :decimal                     then "9.99"
          when :datetime, :timestamp, :time then Time.now.to_s(:db)
          when :date                        then Date.today.to_s(:db)
          when :string                      then prefix + name.camelize + "String"
          when :text                        then prefix + name.camelize + "Text"
          when :boolean                     then false
          else
            ""
        end      
      end
      
      def flex_type
        @flex_type = case type
          when :integer                     then 'int'
          when :string, :text               then 'String'
          when :date, :datetime, :time      then 'Date'
          when :boolean                     then 'Boolean'
          when :float, :decimal             then 'Number'
          else
            '*'
        end
      end
      
      def flex_default(prefix = '')
        @flex_default = case type
          when :integer, :float, :decimal   then '0'
          when :string, :text               then '""'
          when :boolean                     then 'false'
          else
            'null'
        end
      end
    end
  end
end

class RubossScaffoldGenerator < Rails::Generator::NamedBase
  include Ruboss::Configuration 
  
  attr_reader   :project_name, 
                :flex_project_name, 
                :base_package, 
                :base_folder, 
                :command_controller_name

  attr_reader   :belongs_tos, 
                :has_manies,
                :has_ones,
                # added for restful_authentication integration
                :with_user
    
  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name
                
  attr_accessor :constructor_args
  
  # Attribute readers and such from Restful Authentication Plugin
  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name,
                :controller_file_name,
                # added for ease
                :user_model_singular,
                :user_model_plural
  alias_method  :controller_table_name, :controller_plural_name
  attr_reader   :model_controller_name,
                :model_controller_class_path,
                :model_controller_file_path,
                :model_controller_class_nesting,
                :model_controller_class_nesting_depth,
                :model_controller_class_name,
                :model_controller_singular_name,
                :model_controller_plural_name
  alias_method  :model_controller_file_name,  :model_controller_singular_name
  alias_method  :model_controller_table_name, :model_controller_plural_name
  
  attr_accessor :constructor_args
                  
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name
      
  def initialize(runtime_args, runtime_options = {})
    super
    
    if @args.empty?
      puts <<-USAGE
  You must supply at least one model attribute (i.e. database column); 
  it will be used as the label field for generated the ActionScript models.
  
  Ruboss scaffold Example:
  script/generate ruboss_scaffold Task name:string complete:boolean due_date:date_time user_id:integer
  
  Attachment Fu with Ruboss scaffold Example:
  script/generate ruboss_scaffold Task name:string complete:boolean due_date:date_time user_id:integer
  --attachment
  
  Restful Authentication with Ruboss saffold Example:
  script/generate ruboss_scaffold user sessions --authenticated
  
  USAGE
      exit(0)
    end
    
    @project_name, @flex_project_name, @command_controller_name, @base_package, @base_folder = extract_names
    
    # If you specified the restful_authentication option: --authenticated
    # This block of code was basically immported from the restful_authentication plugin...
    if options[:authenticated]
      @rspec = has_rspec?

      @controller_name = 'sessions'
      @model_controller_name = @name.pluralize
      
      # sessions controller
      base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
      @controller_class_name_without_nesting, @controller_file_name, @controller_plural_name = inflect_names(base_name)
      @controller_singular_name = @controller_file_name.singularize

      if @controller_class_nesting.empty?
        @controller_class_name = @controller_class_name_without_nesting
      else
        @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
      end

      # model controller
      base_name, @model_controller_class_path, @model_controller_file_path, @model_controller_class_nesting, @model_controller_class_nesting_depth = extract_modules(@model_controller_name)
      @model_controller_class_name_without_nesting, @model_controller_singular_name, @model_controller_plural_name = inflect_names(base_name)
    
      if @model_controller_class_nesting.empty?
        @model_controller_class_name = @model_controller_class_name_without_nesting
      else
        @model_controller_class_name = "#{@model_controller_class_nesting}::#{@model_controller_class_name_without_nesting}"
      end
      
      @user_model_singular = @model_controller_singular_name
      @user_model_plural = @model_controller_plural_name
    
    # If you specified the attachment_fu option, or you omitted options: --attachment (or nothing)
    # This block of code is from the Ruboss plugin...
    else
      @controller_name = @name.pluralize
      
      base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, 
        @controller_class_nesting_depth = extract_modules(@controller_name)
        @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    
      @controller_singular_name=base_name.singularize
      if @controller_class_nesting.empty?
        @controller_class_name = @controller_class_name_without_nesting
      else
        @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
      end
    end

    @belongs_tos = []
    @has_ones = []
    @has_manies = []
    # Figure out has_one, has_many and belongs_to based on args
    @args.each do |arg|
      if arg =~ /^has_one:/
        # arg = "has_one:arg1,arg2", so all the has_one are together
        @has_ones = arg.split(':')[1].split(',')
      elsif arg =~ /^has_many:/
        # arg = "has_many:arg1,arg2", so all the has_many are together 
        @has_manies = arg.split(":")[1].split(",")
      elsif arg =~ /^belongs_to:/ # belongs_to:arg1,arg2
        @belongs_tos = arg.split(":")[1].split(',')
      elsif arg =~ /^with_user:/ # with:user
        # arg = "with_user:user", used to wire a rails_controller.rb for user authentication
        @with_user = arg.split(":")[1].split(',')
      end
    end
    
    # Remove the has_one and has_many arguments since they are
    # not for consumption by the scaffold generator, and since
    # we have already used them to set the @belongs_tos, @has_ones and
    # @has_manies.
    @args.delete_if { |elt| elt =~ /^(has_one|has_many|belongs_to):/ }
  end
  
  def manifest
    record do |m|
      m.dependency 'scaffold', [name] + @args, :skip_migration => true, :collision => :skip unless options[:flex_only]
      
      # Attachment_fu configuration...
      if options[:attachment_fu]
        m.template 'attachment_fu/model.rb',      File.join('app/models', class_path, "#{file_name}.rb")

        m.template 'attachment_fu/controller.rb', File.join('app/controllers', class_path, "#{file_name.pluralize}_controller.rb")

        m.template 'attachment_fu/model.as.erb',
          File.join("app", "flex", base_folder, "models", "#{@class_name}.as"), 
          :assigns => { :ruboss_controller_name => "#{file_name.pluralize}" } 

        # copied these from below because they weren't working and i didn't want to mess with it...     
        m.template 'attachment_fu/component.mxml.erb',
          File.join("app", "flex", base_folder, "components", "generated", "#{@class_name}Box.mxml"), 
          :assigns => { :ruboss_controller_name => "#{file_name.pluralize}" }
        m.route_resources table_name

        # Create Custom RESTful Command classes based on Model
        # (AppEvents and the AppController are created using the rconfig command)
        m.directory File.join('app/flex', base_folder, "commands")
        m.directory File.join('app/flex', base_folder, "business")
        m.template 'attachment_fu/command.as.erb', File.join('app/flex', base_folder, 'commands', "#{@class_name}Command.as")
        m.template 'attachment_fu/file_delegate.as.erb', File.join('app/flex', base_folder, 'business', "FileDelegate.as")

        unless options[:skip_migration]
          m.migration_template 'attachment_fu/migration.rb.erb', 'db/migrate', :assigns => {
            :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}" },
            :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
        end

        m.template 'attachment_fu/fixtures.yml.erb', File.join('test/fixtures', "#{table_name}.yml")

      # Restful_Authentication configuration...
      else if options[:authenticated]
        # Check for class naming collisions.
        m.class_collisions controller_class_path,       "#{controller_class_name}_controller", # Sessions Controller
                                                        "#{controller_class_name}_helper"
        m.class_collisions model_controller_class_path, "#{model_controller_class_name}_controller", # Model Controller
                                                        "#{model_controller_class_name}_helper"
        m.class_collisions class_path,                  "#{class_name}", "#{class_name}_mailer", "#{class_name}_mailer_mest", "#{class_name}_observer"
        m.class_collisions [], 'AuthenticatedSystem', 'AuthenticatedTestHelper'

        # Controller, helper, views, and test directories.
        m.directory File.join('app/models', class_path)
        m.directory File.join('app/controllers', controller_class_path)
        m.directory File.join('app/controllers', model_controller_class_path)
        m.directory File.join('app/helpers', controller_class_path)
        m.directory File.join('app/views', controller_class_path, controller_file_name)
        m.directory File.join('app/views', class_path, "#{file_name}_mailer") if options[:include_activation]

        m.directory File.join('app/controllers', model_controller_class_path)
        m.directory File.join('app/helpers', model_controller_class_path)
        m.directory File.join('app/views', model_controller_class_path, model_controller_file_name)

        if @rspec
          m.directory File.join('spec/controllers', controller_class_path)
          m.directory File.join('spec/controllers', model_controller_class_path)
          m.directory File.join('spec/models', class_path)
          m.directory File.join('spec/fixtures', class_path)
        else
          m.directory File.join('test/functional', controller_class_path)
          m.directory File.join('test/functional', model_controller_class_path)
          m.directory File.join('test/unit', class_path)
        end

        m.template 'restful_authentication/model.rb',
                    File.join('app/models', class_path, "#{file_name}.rb")

        if options[:include_activation]
          %w( mailer observer ).each do |model_type|
            m.template "restful_authentication/#{model_type}.rb", File.join('app/models', class_path, "#{file_name}_#{model_type}.rb")
          end
        end

        m.template 'restful_authentication/controller.rb',
                    File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")

        m.template 'restful_authentication/model_controller.rb',
                    File.join('app/controllers', model_controller_class_path, "#{model_controller_file_name}_controller.rb")

        m.template 'restful_authentication/authenticated_system.rb',
                    File.join('lib', 'authenticated_system.rb')

        m.template 'restful_authentication/authenticated_test_helper.rb',
                    File.join('lib', 'authenticated_test_helper.rb')

        if @rspec
          m.template 'restful_authentication/functional_spec.rb',
                      File.join('spec/controllers', controller_class_path, "#{controller_file_name}_controller_spec.rb")
          m.template 'restful_authentication/model_functional_spec.rb',
                      File.join('spec/controllers', model_controller_class_path, "#{model_controller_file_name}_controller_spec.rb")
          m.template 'restful_authentication/unit_spec.rb',
                      File.join('spec/models', class_path, "#{file_name}_spec.rb")
          m.template 'restful_authentication/fixtures_authenticate.yml',
                      File.join('spec/fixtures', "#{table_name}.yml")
        else
          m.template 'restful_authentication/functional_test.rb',
                      File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb")
          m.template 'restful_authentication/model_functional_test.rb',
                      File.join('test/functional', model_controller_class_path, "#{model_controller_file_name}_controller_test.rb")
          m.template 'restful_authentication/unit_test.rb',
                      File.join('test/unit', class_path, "#{file_name}_test.rb")

          if options[:include_activation]
            m.template 'restful_authentication/mailer_test.rb', File.join('test/unit', class_path, "#{file_name}_mailer_test.rb")
          end
          m.template 'restful_authentication/fixtures.yml.erb',
                      File.join('test/fixtures', "#{table_name}.yml")
        end

        m.template 'restful_authentication/helper.rb',
                    File.join('app/helpers', controller_class_path, "#{controller_file_name}_helper.rb")

        m.template 'restful_authentication/model_helper.rb',
                    File.join('app/helpers', model_controller_class_path, "#{model_controller_file_name}_helper.rb")

        # Rails View templates
        m.directory File.join('app/views', controller_class_path, controller_file_name)
        m.directory File.join('app/views', model_controller_class_path, model_controller_file_name)
        m.template 'restful_authentication/login.html.erb',  File.join('app/views', controller_class_path, controller_file_name, "new.html.erb")
        m.template 'restful_authentication/signup.html.erb', File.join('app/views', model_controller_class_path, model_controller_file_name, "new.html.erb")

        # Flex Login and Account View templates
        m.directory File.join('app/flex', base_package, "components/generated/users")
        m.template 'restful_authentication/login.mxml.erb', File.join('app/flex', base_package, "components/generated/users", "LoginBox.mxml")
        m.template 'restful_authentication/signup.mxml.erb', File.join('app/flex', base_package, "components/generated/users", "SignupBox.mxml")
        m.template 'restful_authentication/account.mxml.erb', File.join('app/flex', base_package, "components/generated/users", "AccountBox.mxml")

        # Flex Login and Session Command templates
        m.template 'restful_authentication/command.as.erb', File.join('app/flex', base_package, "commands", "SessionsCommand.as")
        m.template 'restful_authentication/model_command.as.erb', File.join('app/flex', base_package, "commands", "#{@class_name}Command.as")

        m.template 'restful_authentication/model.as.erb',
          File.join("app", "flex", base_folder, "models", "#{@class_name}.as"), 
          :assigns => { :ruboss_controller_name => "#{file_name.pluralize}" }

        # Validators for Flex Login and Account Creation (from Pomodo at FlexibleRails)
        m.directory "app/flex/com/pomodo/validators"
        %w(PasswordConfirmationValidator.as ServerErrors.as ServerErrorValidator.as).each do |file|
          m.file "restful_authentication/validators/#{file}", "app/flex/com/pomodo/validators/#{file}"
        end

        if options[:include_activation]
          # Mailer templates
          %w( activation signup_notification ).each do |action|
            m.template "restful_authentication/#{action}.html.erb",
                File.join('app/views', "#{file_name}_mailer", "#{action}.html.erb")
          end
        end

        unless options[:skip_migration]
          m.migration_template 'restful_authentication/migration.rb.erb', 'db/migrate', :assigns => {
            :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}" },
            :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
        end
        
      # If no plugins are specified, this is what you will get...
      else
        # Generate Flex AS model and MXML component based on the
        # Ruboss templates.
        m.template 'ruboss_scaffold/model.as.erb',
          File.join("app", "flex", base_folder, "models", "#{@class_name}.as"), 
          :assigns => { :resource_controller_name => "#{file_name.pluralize}" }

        m.template 'ruboss_scaffold/component.mxml.erb',
          File.join("app", "flex", base_folder, "components", "generated", "#{@class_name}Box.mxml"), 
          :assigns => { :resource_controller_name => "#{file_name.pluralize}" }

        # Create Custom RESTful Command classes based on the Model
        # (AppEvents and the AppController are created using the ruboss_config command)
        m.directory File.join('app/flex', base_folder, "commands")
        m.template 'ruboss_scaffold/command.as.erb', File.join('app/flex', base_folder, 'commands', "#{@class_name}Command.as")

        m.template 'ruboss_scaffold/controller.rb.erb', File.join("app/controllers", controller_class_path, 
          "#{controller_file_name}_controller.rb"), :collision => :force unless options[:flex_only]

        # Create a new generated ActiveRecord model based on the Ruboss templates.
        m.template 'ruboss_scaffold/model.rb.erb', File.join("app", "models", "#{file_name}.rb"), 
          :collision => :force unless options[:flex_only]

        unless options[:skip_fixture] 
          m.template 'ruboss_scaffold/fixtures.yml.erb',  File.join("test", "fixtures", "#{table_name}.yml"), 
            :collision => :force unless options[:flex_only]
        end

        unless options[:skip_migration]
          m.migration_template 'ruboss_scaffold/migration.rb.erb', 'db/migrate', :assigns => {
            :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
          }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}" unless options[:flex_only]
        end
      end
    end

      # Run the rcontroller generator to clobber the
      # RubossCommandController subclass to include the new models.
      m.dependency 'ruboss_controller', [name] + @args, :collision => :force
    end
  end
  
  protected
    def has_rspec?
      options[:rspec] || (File.exist?('spec') && File.directory?('spec'))
    end
    
    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("-f", "--flex-only", "Scaffold Flex code only", 
        "Default: false") { |v| options[:flex_only] = v}
      opt.on("--attachment", 
        "Generate signup 'activation code' confirmation via email") { |v| options[:attachment_fu] = true }
      opt.on("--authenticated", 
        "Generate authenticated user and sessions") { |v| options[:authenticated] = true }
      opt.on("--skip-migration", 
        "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
      opt.on("--include-activation", 
       "Generate signup 'activation code' confirmation via email") { |v| options[:include_activation] = true }
      opt.on("--stateful", 
       "Use acts_as_state_machine.  Assumes --include-activation") { |v| options[:include_activation] = options[:stateful] = true }
      opt.on("--rspec",
       "Force rspec mode (checks for RAILS_ROOT/spec by default)") { |v| options[:rspec] = true }
    end
end