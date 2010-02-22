module ActiveRecord
  module Acts
    module BetterTree
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_better_tree(options = {}, &b)
          configuration = {:order => "id ASC", :counter_cache => nil, :destroy_dependent => true }
          configuration.update(options) if options.is_a?(Hash)
          
          belongs_to :parent, :class_name => name, :foreign_key => :parent_id, :counter_cache => configuration[:counter_cache]
          has_many :children, {:class_name => name, :foreign_key => :parent_id, :order => configuration[:order]}.merge(configuration[:destroy_dependent] ? {:dependent => :destroy} : {}), &b
          has_many :parents_children, {:class_name => name, :primary_key => :parent_id, :foreign_key => :parent_id, :order => configuration[:order]}, &b
          
          named_scope :roots, :order => configuration[:order], :conditions => {:parent_id => nil}
          after_save                 :assign_csv_ids
          after_validation_on_update :update_csv_ids
          
          class_eval do
            include ActiveRecord::Acts::BetterTree::InstanceMethods

            def self.root(options = {})
              self.roots(options).first
            end
            
            def parent_foreign_key_changed?
              parent_id_changed?
            end
          end
        end

        def traverse(nodes = nil, &block)
          nodes ||= self.roots
          nodes.each do |node|
            yield node
            traverse(node.children, &block)
          end
        end
        
        # Call this to upgrade an existing acts_as_tree to acts_as_better_tree
        def rebuild_csv_ids!
          transaction do
            traverse { |node| node.csv_ids = nil; node.save! }
          end
        end
        
      end
      
      module InstanceMethods
        def ancestors
          if self.csv_ids
            ids = self.csv_ids.split(',')[0...-1]
            (@ancestors ||= self.class.find(:all, :conditions => {:id => ids}, :order => 'csv_ids ASC'))
          else
            node, nodes = self, []
            nodes << node = node.parent while node.parent
            (@ancestors ||= nodes.reverse)
          end
        end
        
        def self_and_ancestors
          ancestors + [self]
        end
        
        def root
          if self.csv_ids
            self.class.find(self.csv_ids.split(',').first)
          else
            node = self
            node = node.parent while node.parent
            node
          end
        end
        
        def siblings
          self_and_siblings - [self]
        end
        
        def self_and_siblings
          unless parent_id.blank?
            self.parents_children
          else
            self.class.roots
          end
        end
        
        def ancestor_of?(node)
          node.csv_ids.length > self.csv_ids.length && node.csv_ids.starts_with?(self.csv_ids)
        end
        
        def descendant_of?(node)
          self.csv_ids.length > node.csv_ids.length && self.csv_ids.starts_with?(node.csv_ids)
        end
        
        def all_children(options = {})
          find_all_children_with_csv_ids(nil, options)
        end
        
        def self_and_all_children
          [self] + all_children
        end
        
        def depth
          self.csv_ids.scan(/\,/).size
        end
        
        def childless?
          return self.class.find(:first, :conditions => ['csv_ids LIKE ?', csv_id_like_pattern]).blank?
        end

        def root?
          return self.parent.blank?
        end
        
        def move_to_child_of(category)
          self.update_attributes(:parent_id => category.id)
        end
        
        def make_root
          self.update_attributes(:parent_id => nil)
        end
        
        protected
        
        def csv_id_like_pattern(prefix = nil)
          (prefix || self.csv_ids) + ',%'
        end
        
        def find_all_children_with_csv_ids(prefix = nil, options = {})
          conditions = [self.class.send(:sanitize_sql, ['csv_ids LIKE ?', csv_id_like_pattern(prefix)])]
          conditions << "(#{self.class.send(:sanitize_sql, options[:conditions])})" unless options[:conditions].blank?
          options.update(:conditions => conditions.join(" AND "))
          self.class.find(:all, options)
        end
        
        def build_csv_ids
          self.parent.blank? ? self.id.to_s : "#{self.parent.csv_ids},#{self.id}"
        end
        
        def assign_csv_ids
          self.update_attribute(:csv_ids, build_csv_ids) if self.csv_ids.blank?
        end
        
        def update_csv_ids
          return unless parent_foreign_key_changed?
          old_csv_ids = self.csv_ids
          self.csv_ids = build_csv_ids
          self.class.update_all("csv_ids = Replace(csv_ids, '#{old_csv_ids}', '#{self.csv_ids}')", "csv_ids like '#{old_csv_ids}%'")
        end
      end
    end
  end
end