class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
<% for attribute in attributes -%>
<% if attribute.name == "with_user" %>
      # belongs_to the following...
      <% else %>      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>
<% end -%>
<% for model in belongs_tos -%>
      t.references :<%= model %>
<% end -%>
<% unless options[:skip_timestamps] %>
      t.timestamps
<% end -%>
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end