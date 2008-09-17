class <%= model_controller_class_name %>Controller < ApplicationController
  skip_before_filter :login_required, :only => [ :new, :create ]
  
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  # Add the following to the config/routes.rb file to create elegant url maps:
  # map.activate '/activate/:activation_code', :controller => '#{model_controller_file_name}', :action => 'activate'
  # map.signup '/signup', :controller => '#{model_controller_file_name}', :action => 'new'
  # map.login '/login', :controller => '#{controller_file_name}', :action => 'new'
  # map.logout '/logout', :controller => '#{controller_file_name}', :action => 'destroy'
    # If you included the --include-activation option, then at the following to the config/environment.rb file:
      # config.active_record.observers = :#{file_name}_observer
    # If you included the --stateful option:
    # 1) install the acts_as_state_machine plugin:
      # svn export http://elitists.textdriven.com/svn/plugins/acts_as_state_machine/trunk vendor/plugins/acts_as_state_machine
    # 2) add the following to the config/routes.rb file:
      # map.resources :#{model_controller_file_name}, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  
  <% if options[:stateful] %>
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_<%= file_name %>, :only => [:suspend, :unsuspend, :destroy, :purge]
  <% end %>
  
  def index
    @<%= file_name %> = <%= class_name %>.find(:all)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @<%= file_name %> }
      format.fxml  { render :fxml => @<%= file_name %> }
    end
  end
  
  # render new.rhtml
  def new
  end
  
  # POST /<%= file_name.pluralize %>
  # POST /<%= file_name.pluralize %>.xml
  def create
     cookies.delete :auth_token
     # protects against session fixation attacks, wreaks havoc 
     # wreaks request forgery protection.
     # uncomment at your own risk
     # reset_session
     @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
     if @<%= file_name %>.save
       self.current_<%= file_name %> = @<%= file_name %>
       respond_to do |format|
         format.html do
           redirect_back_or_default('/')
           flash[:notice] = "Thanks for signing up!"
         end
         format.xml  { render :xml => @<%= file_name %>, :status => :created, :location => @<%= file_name %> }
         format.fxml  { render :fxml => @<%= file_name %> }
       end
     else
       format.html { render :action => "new" }
       format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
       format.fxml  { render :fxml => @<%= file_name %>.errors }
     end
   end
   rescue ActiveRecord::RecordInvalid
     respond_to do |format|
       format.html { render :action => 'new' }
       format.xml do
         unless @<%= file_name %>.errors.empty?
           render :xml => @<%= file_name %>.errors.to_xml_full
         else
           render :text => "error"
         end
       end
     end
  
  # DELETE /<%= file_name.pluralize %>/1
  # DELETE /<%= file_name.pluralize %>/1.xml
  def destroy
    if current_<%= file_name %>.id == params[:id].to_i &&
      current_<%= file_name %>.destroy
      cookies.delete :auth_token
      reset_session
      render :text => "success"
    else
      render :text => "error"
    end
  end
<% if options[:include_activation] %>
  def activate
    self.current_<%= file_name %> = params[:activation_code].blank? ? false : <%= class_name %>.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_<%= file_name %>.active?
      current_<%= file_name %>.activate<% if options[:stateful] %>!<% end %>
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end
<% end %><% if options[:stateful] %>
  def suspend
    @<%= file_name %>.suspend! 
    redirect_to <%= table_name %>_path
  end

  def unsuspend
    @<%= file_name %>.unsuspend! 
    redirect_to <%= table_name %>_path
  end

  def destroy
    @<%= file_name %>.delete!
    redirect_to <%= table_name %>_path
  end

  def purge
    @<%= file_name %>.destroy
    redirect_to <%= table_name %>_path
  end

protected
  def find_<%= file_name %>
    @<%= file_name %> = <%= class_name %>.find(params[:id])
  end
<% end %>
end
