module RubossHelper
  
  # Creates a swfObject Javascript call.  You must include swfobject.js to use this.
  # See http://code.google.com/p/swfobject/wiki/documentation for full details and documentation
  # of the swfobject js library.
  def swfobject(swf_url, params = {})
    params.reverse_merge!({:width => '900',
                           :height => '600',
                           :id => 'flashContent',
                           :version => '9.0.0',
                           :express_install_swf => nil,
                           :flash_vars => nil,
                           :params => nil,
                           :attributes => nil,
                           :create_div => false, 
                           :include_authenticity_token => true
                          })                       
    arg_order = [:id, :width, :height, :version, :express_install_swf]
    js_params = ["'#{swf_url}?#{rails_asset_id(swf_url)}'"]
    js_params += arg_order.collect {|arg| "'#{params[arg]}'" }
    
    # Add authenticity_token to flashVars.  This will only work if flashVars is a Hash or nil
    # If it's a string representing the name of a Javascript variable, then you need to add it yourself 
    # like this:
    # <script>
    #   ... other code that defines flashVars and sets some of its parameters
    #   flashVars['authenticity_token'] = <%= form_authenticity_token -%>
    # </script>
    # If you include an authenticity_token parameter in flashVars, 
    # then the Flex app will add it to Ruboss.defaultMetadata, so that it will be sent
    # back up to your Rails app with every request.
    if params[:include_authenticity_token] && ActionController::Base.allow_forgery_protection
      params[:flash_vars] = {} if params[:flash_vars].nil?
      if params[:flash_vars].is_a?(Hash)
        params[:flash_vars].reverse_merge!(:authenticity_token => form_authenticity_token)
      end
    end
    
    js_params += [params[:flash_vars], params[:params], params[:attributes]].collect do |hash_or_string|
      if hash_or_string.is_a?(Hash)
        hash_or_string.to_json
      else # If it's not a hash, then it should be a string giving the name of the Javascript variable to use
        hash_or_string
      end
    end.compact


    swf_tag = javascript_tag do 
      "swfobject.embedSWF(#{js_params.join(',')})"
    end 
    swf_tag += content_tag(:div, nil, :id => params[:id]) if params[:create_div]    
    swf_tag
  end
  
end
