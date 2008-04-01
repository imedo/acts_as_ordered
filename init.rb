# Include hook code here
require 'acts_as_ordered'

ActiveRecord::Base.send(:include, Thc2::Acts::Ordered)
