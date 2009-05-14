require 'rubygems'

require 'dry_plugin_test_helper'
require 'mocha'

PluginTestEnvironment.initialize_environment(File.dirname(__FILE__), :rails_version => '2.0.2')
Article.acts_as_ordered
