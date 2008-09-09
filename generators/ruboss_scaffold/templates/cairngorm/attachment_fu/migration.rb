class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column "content_type", :string
      t.column "directory", :string
      t.column "filename", :string     
      t.column "size", :integer
      
      # used with thumbnails, always required
      t.column "parent_id",  :integer 
      t.column "thumbnail", :string
      
      # required for images only
      t.column "width", :integer  
      t.column "height", :integer
      
      # custom attributes specified in the command line
      <% for attribute in attributes -%>
      <% if attribute.name == "with_user" %>
            # belongs_to the following...
      <% else %>      t.<%= attribute.type %> :<%= attribute.name %>
      <% end -%>
      <% end -%>
      
      <% for model in belongs_tos -%>
            t.references :<%= model %>
      <% end -%>
      
      t.timestamps
    end

    # only for db-based files
    # create_table :db_files, :force => true do |t|
    #      t.column :data, :binary
    # end
  end

  def self.down
    drop_table :<%= table_name %>
    
    # only for db-based files
    # drop_table :db_files
  end
end
