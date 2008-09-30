class <%= class_name.pluralize %>Controller < ApplicationController
  require 'zip/zipfilesystem'
  
  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index<% if with_user %>
    @<%= table_name %> = current_<%= with_user %>.<%= table_name %>
  <% else %>
  	@<%= table_name %> = <%= class_name %>.find(:all)
  <% end -%>

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @<%= table_name %> }
      format.fxml  { render :fxml => @<%= table_name %> }
    end
  end

  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show<% if with_user %>
    @<%= file_name %> = current_<%= with_user %>.<%= table_name %>.find(params[:id])
  <% else %>
  	@<%= file_name %> = <%= class_name %>.find(params[:id])
  <% end -%>

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%= file_name %> }
      format.fxml  { render :fxml => @<%= file_name %> }
    end
  end

  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= file_name %> = <%= class_name %>.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%= file_name %> }
      format.fxml  { render :fxml => @<%= file_name %> }
    end
  end

  # GET /<%= table_name %>/1/edit
  def edit<% if with_user %>
    @<%= file_name %> = current_<%= with_user %>.<%= table_name %>.find(params[:id])
  <% else %>
  	@<%= file_name %> = <%= class_name %>.find(params[:id])
  <% end -%>
    rescue ActiveRecord::RecordNotFound => e
    	prevent_access(e)
  end
  
  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  # POST /<%= table_name %>.fxml
  def create<% if with_user %>
    @<%= file_name %> = current_<%= with_user %>.<%= table_name %>.build(params[:<%= file_name %>])
  <% else %>
  	@<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
  <% end -%>
  
    respond_to do |format|
      if @<%= file_name %>.save
        flash[:notice] = '<%= class_name %> was successfully created.'
        format.html { redirect_to(@<%= file_name %>) }
        format.xml  { render :xml => @<%= file_name %>, :status => :created, :location => @<%= file_name %> }
        format.fxml  { render :fxml => @<%= file_name %> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
        format.fxml  { render :fxml => @<%= file_name %>.errors }
      end
    end
  end
  
  # POST /<%= table_name %>
  def upload
    @file_data = params[:Filedata]
    @file_name = params[:Filename]
    # the :user parameter below comes straight from the URLVariables "user" in Flex!<% if with_user %>
    if params[:user]
      @login = params[:user]
      @<%= with_user %> = <%= with_user.to_s.capitalize %>.find(:first, :conditions => {:login => @login})
      @<%= file_name %> = <%= class_name %>.create!(:uploaded_data => @file_data,
                :directory => "assets/<%= table_name %>",
                :<%= with_user %>_id => @<%= with_user %>.id)
    else
      @<%= file_name %> = <%= class_name %>.create!(:uploaded_data => @file_data,
                :directory => "assets/<%= table_name %>")
    end
    <% else %>
    	@<%= file_name %> = <%= class_name %>.create!(:uploaded_data => @file_data,
                :directory => "assets/<%= table_name %>")
    <% end -%>
    respond_to do |format|
      if @<%= file_name %>.save
        format.xml  { render :xml => @<%= file_name %> }
        format.fxml  { render :fxml => @<%= file_name %> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
        format.fxml  { render :fxml => @<%= file_name %>.errors }
      end
    end
  end
  
  def download
    files_array = params[:filename].split(',')
    file_path = params[:directory]
    
    if(File.exist?("archive.zip")) 
      File.delete("archive.zip") 
    end
    
    Zip::ZipFile.open("archive.zip", Zip::ZipFile::CREATE) {
      |zipfile|
      files_array.each{
        |filename|
        zipfile.file.open(filename, "w") {
          |new_file|
          File.open(file_path + "/" + filename, "rb"){ |file_content|  new_file.write(file_content.read)}
        }
      }
    }
    send_file 'archive.zip'
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update<% if with_user %>
    @<%= file_name %> = current_<%= with_user %>.<%= table_name %>.find(params[:id])
  <% else %>
  	@<%= file_name %> = <%= class_name %>.find(params[:id])
  <% end -%>

    respond_to do |format|
      if @<%= file_name %>.update_attributes(params[:<%= file_name %>])
        flash[:notice] = '<%= class_name %> was successfully updated.'
        format.html { redirect_to(@<%= file_name %>) }
        format.xml  { head :ok }
        format.fxml  { render :fxml => @<%= file_name %> }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%= file_name %>.errors, :status => :unprocessable_entity }
        format.fxml  { render :fxml => @<%= file_name %>.errors }
      end
    end
  end

  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy<% if with_user %>
    @<%= file_name %> = current_<%= with_user %>.<%= table_name %>.find(params[:id])
  <% else %>
  	@<%= file_name %> = <%= class_name %>.find(params[:id])
  <% end -%>
    @<%= file_name %>.destroy

    respond_to do |format|
      format.html { redirect_to(<%= table_name %>_url) }
      format.xml  { head :ok }
      format.fxml  { render :fxml => @<%= file_name %> }
    end
  end
end