class <%= class_name %> < ActiveRecord::Base
  has_attachment :content_type => :image, 
                 :storage => :file_system,
                 :path_prefix => "public/assets" # Change this for custom file location.
  
<% for model in belongs_tos -%>
  belongs_to :<%= model %>
<% end -%>
<% for model in has_ones -%>
  has_one :<%= model %>
<% end -%>
<% for model in has_manies -%>
  has_many :<%= model %>
<% end -%>
  # Override attachment_fu uploaded_data method to change the "application/octet-stream"
  # content type back to the original. For reference.
  def uploaded_data=(file_data)
    return nil if file_data.nil? || file_data.size == 0
    self.filename = file_data.original_filename if respond_to?(:filename)
    if file_data.is_a?(StringIO)
      file_data.rewind
      self.temp_data = file_data.read
    else
      self.temp_path = file_data.path
    end
    # in the original the next line occured earlier, and just used file_data.content_type
    self.content_type = get_content_type((file_data.content_type.chomp if file_data.content_type))
  end

  # Uses the operating system's “file” utility to determine the file type,
  # yanked and modified slightly from file_column.
  def get_content_type(fallback=nil)
    begin
      content_type = `file -bi “#{File.join(temp_path)}“`.chomp
      content_type = fallback unless $?.success?
      content_type.gsub!(/;.+$/,““) if content_type
      content_type
    rescue
      fallback
    end
  end

  def full_filename(thumbnail = nil)
      file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix].to_s
      File.join(RAILS_ROOT, file_system_path, thumbnail_name_for(thumbnail))
  end
end
