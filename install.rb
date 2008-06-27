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