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
require 'ruboss_version'
require 'ruboss_rails_integration'

ActionView::Base.send :include, RubossHelper

# temporarily disable forgery protection site-wise
ActionController::Base.allow_forgery_protection = false

ActionController::Base.send :include, RubossController
ActionController::Base.send :prepend_before_filter, :extract_metadata_from_params  
Test::Unit::TestCase.send :include, RubossTestHelpers
