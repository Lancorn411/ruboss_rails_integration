# This controller handles the login/logout function of the site.  
class <%= controller_class_name %>Controller < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  # GET /session/new
  # GET /session/new.xml
  # render new.rhtml
  def new
  end

  # POST /session
  # POST /session.xml
  def create
    self.current_<%= file_name %> = <%= class_name %>.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_<%= file_name %>.remember_me
        cookies[:auth_token] = {
          :value => self.current_<%= file_name %>.remember_token ,
          :expires =>
            self.current_<%= file_name %>.remember_token_expires_at }
      end
      respond_to do |format|
        format.xml  { render :xml => self.current_<%= file_name %>.to_xml }
      end
    else
      respond_to do |format|
        # Comment out html version or else it doesn't work
        # format.html { render :action => 'new' }
        format.xml { render :text => "badLogin" }
        format.fxml  { render :text => "badLogin" }
      end
    end
  end

  def destroy
    self.current_<%= file_name %>.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    respond_to do |format|
      format.xml { render :text => "loggedOut" }
      format.fxml { render :text => "loggedOut" }
    end
  end
end
