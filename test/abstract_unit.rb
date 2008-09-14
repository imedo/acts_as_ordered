require 'rubygems'

require 'dry_plugin_test_helper'
require 'mocha'

PluginTestEnvironment.init_env(File.dirname(__FILE__))
Article.acts_as_ordered
