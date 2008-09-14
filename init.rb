# Include hook code here
require 'acts_as_ordered'
require 'core_ext/array'
require 'core_ext/hash'

ActiveRecord::Base.send(:include, Thc2::Acts::Ordered)
