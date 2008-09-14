# ActsAsOrdered
module Thc2 #:nodoc:
  module Acts #:nodoc:
    module Ordered #:nodoc:
      def self.included(base) #:nodoc:
        base.extend ClassMethods  
      end
      
      # This module contains acts methods
      module ClassMethods
        # This acts allows you to access the logical next and previous element in a database result set that is
        # specified by the :conditions and :order parameters.
        #
        # For example, if Picture p belongs to User u, you can get the next picture belonging to u by calling
        #
        #    p.find_next(:conditions => ['user_id = ?', u.id])
        #
        # Alternatively, you can use the :source parameter:
        #
        #    Picture.find(:next, :source => p, :conditions => ['user_id = ?', u.id])
        #
        # Note that you need to give the user id explicitly; the p variable does not store the context of the
        # result set in which you want to find the logical next and previous items.
        #
        # ActiveRecord's :order parameter is of course taken into account:
        #
        #    p.find_next(:conditions => ['user_id = ?', u.id], :order => 'created_at ASC')
        #    # equals
        #    p.find_prev(:conditions => ['user_id = ?', u.id], :order => 'created_at DESC')
        #
        # You can even use multiple order columns, with different sort directions. If you don't specify any
        # order, a default of 'id ASC' is assumed.
        #
        # The next or previous item is found efficiently: The generated SQL ensures that only one item gets
        # returned from the database.
        def acts_as_ordered(options = {})
          return if self.included_modules.include?(Thc2::Acts::Ordered::InstanceMethods)
          
          include Thc2::Acts::Ordered::InstanceMethods
          extend Thc2::Acts::Ordered::SingletonMethods
          class << self
            alias_method_chain :find, :ordered
            alias_method_chain :find_initial, :ordered
            alias_method_chain :find_every, :ordered
          end
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Finds the logical next or previous element in a database result set, relative to self. To find the
        # next element, use :next as the first parameter. To find the previous, use :prev.
        def find(*args)
          options = args.extract_options!
          options[:source] = self
          args.push(options)
          self.class.find(*args)
        end
        
        # Finds the logical next element in a database result set, relative to self.
        def find_next(*args)
          find(:next, *args)
        end
        
        # Finds the logical previous element in a database result set, relative to self.
        def find_prev(*args)
          find(:prev, *args)
        end
        
        def find_next_and_prev(*args)
          options = args.extract_options!
          options[:source] = self
          args.push(options)
          self.class.find_next_and_prev(*args)
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        def find_with_ordered(*args) #:nodoc:
          args = args.rdup
          options = prepare_options_for_ordered(args)
          case args.first
            when :first then find_initial_without_ordered(options)
            when :all   then find_every_without_ordered(options)
            else             find_without_ordered(*args)
          end
        end
        
        def find_every_with_ordered(*args) #:nodoc:
          args = args.rdup
          prepare_options_for_ordered(args)
          find_every_without_ordered(*args)
        end
        
        def find_initial_with_ordered(*args) #:nodoc:
          args = args.rdup
          prepare_options_for_ordered(args)
          find_initial_without_ordered(*args)
        end
        
        # Finds the logical next item, relative to the object given by the required
        # :source parameter.
        def find_next(*args)
          find(:next, *args)
        end
        
        # Finds the logical previous item, relative to the object given by the required
        # :source parameter.
        def find_prev(*args)
          find(:prev, *args)
        end
        
        # Returns an array containing the logical next and previous items, relative to
        # the object given by the required :source parameter.
        def find_next_and_prev(*args)
          return find(:next, *args), find(:prev, *args)
        end
        
      private
        def prepare_options_for_ordered(args)
          direction = extract_direction_from_args!(args)
          options = args.extract_options!
          unless direction.nil?
            columns = extract_order_from_options!(options, direction)
            methods = extract_methods_from_options!(options, columns)
            source = extract_source_from_options!(options)
            add_direction_to_conditions(options, source, columns, methods, direction)
          end
          args.push(options)
          options
        end
        
        def extract_direction_from_args!(args)
          dir = args[0]
          if dir == :prev || dir == :previous
            args[0] = :first
            return :prev
          elsif dir == :next
            args[0] = :first
            return :next
          else
            return nil
          end
        end
        
        def extract_source_from_options!(options)
          options.delete(:source) || raise("No :source given in ordered find call")
        end
        
        def extract_methods_from_options!(options, columns)
          options.delete(:methods) || columns.collect { |col| col[0] } || 'id'
        end

        def extract_order_from_options!(options, direction)
          columns = (options.delete(:order) || 'id').split(',').collect { |col| col.strip }

          add_id_to_columns!(direction, columns) unless columns_contain_id?(columns)

          if direction == :prev
            options[:order] = columns.collect { |col| reverse_order(col) }.join(", ")
          else
            options[:order] = columns.join(", ")
          end
          columns.collect { |col| [strip_direction(col), col =~ /DESC$/i ? :desc : :asc] }
        end
        
        def add_id_to_columns!(direction, columns)
          columns << 'id ASC'
        end
        
        def columns_contain_id?(columns)
          columns.each do |column|
            return true if strip_direction(column) == 'id'
          end
          return false
        end
        
        def convert_conditions_hash_to_array(conditions)
          return conditions unless conditions.is_a?(Hash)
          keys = conditions.keys
          values = conditions.values
          return [keys.collect { |k| "#{k} = ?" }.join(" AND ")] + values
        end
        
        def add_direction_to_conditions(options, source, columns, methods, direction)
          conditions = options.delete(:conditions)
          
          conditions = convert_conditions_hash_to_array(conditions)

          conditions = [conditions] unless conditions.is_a?(Array)
          restrictions = []
          merged_conditions = []

          columns.reverse.each do |col|
            operator = relational_operator(direction, col[1])
            value = source.send(col[0].to_sym)
            unless restrictions.blank?
              restrictions[0] = "(#{col[0]} = ? AND (#{restrictions[0]})) OR #{col[0]} #{operator} ?"
              restrictions.insert(1, value)
              restrictions << value
            else
              restrictions[0] = "#{col[0]} #{operator} ?"
              restrictions << value
            end
          end

          if !conditions[0].blank? && !restrictions[0].blank?
            merged_conditions << "(#{conditions[0]}) AND (#{restrictions[0]})"
          elsif !conditions[0].blank?
            merged_conditions << conditions[0]
          elsif !restrictions[0].blank?
            merged_conditions << restrictions[0]
          end
          
          conditions.each_with_index do |c, i|
            merged_conditions << c unless i == 0
          end
          restrictions.each_with_index do |r, i|
            merged_conditions << r unless i == 0
          end

          options[:conditions] = merged_conditions
        end
        
        def reverse_order(column)
          if column =~ /ASC$/i
            column.gsub(/ASC$/i, "DESC")
          elsif column =~ /DESC$/i
            column.gsub(/DESC$/i, "ASC")
          else
            # by default, order is ASC, so reversed it would be DESC
            column += " DESC"
          end
        end
        
        def strip_direction(column)
          column.nil? ? nil : column.gsub(/ASC$/i, "").gsub(/DESC$/i, "").strip
        end
        
        def relational_operator(direction, order)
          if direction == :prev
            order == :asc ? '<' : '>'
          else
            order == :asc ? '>' : '<'
          end
        end
      end
    end
  end
end
