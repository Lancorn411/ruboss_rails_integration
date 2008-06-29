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

# Install hook code here
require 'ftools'
require 'open-uri'
require File.dirname(__FILE__) + '/lib/ruboss_version'

# Allows you to run this script from RAILS_ROOT without using script/plugin install
RAILS_ROOT = `pwd`.chomp unless defined?(RAILS_ROOT)

framework_distribution_url = "http://ruboss.com/releases/ruboss-#{FRAMEWORK_RELEASE}.swc"
framework_destination_file = "lib/ruboss-#{FRAMEWORK_RELEASE}.swc"

puts "-----------------"
%w(multiscaffold yamlscaffold).each do |script|
  File.copy(File.dirname(__FILE__) + "/script/#{script}", RAILS_ROOT + '/script')
  File.chmod(0755, ::RAILS_ROOT + "/script/#{script}")
  puts "installing #{script} into script folder"
end

config_file = File.join(File.dirname(__FILE__), 'config', 'ruboss.yml')
target_file = File.join(::RAILS_ROOT, 'config', 'ruboss.yml')
unless File.exist?(target_file)
  File.copy(config_file, target_file)
  puts "copying ruboss.yml into config folder, customize if necessary"
end

unless File.exist?(framework_destination_file)
  puts "fetching #{FRAMEWORK_RELEASE} framework binary from: #{framework_distribution_url} ..."
  open(framework_destination_file, 'wb').write(open(framework_distribution_url).read)
  puts "done. saved to #{framework_destination_file}"
end