require "acts_as_better_tree/version"

module ActiveRecord
  module Acts
    module BetterTree
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_better_tree(options = {}, &b)
          configuration = {:order => "id ASC", :destroy_dependent => true }
          configuration.update(options) if options.is_a?(Hash)

          belongs_to :parent, :class_name => name, :foreign_key => :parent_id
          has_many :children, {:class_name => name, :foreign_key => :parent_id, :order => configuration[:order]}.merge(configuration[:destroy_dependent] ? {:dependent => :destroy} : {}), &b
          has_many :parents_children, {:class_name => name, :primary_key => :parent_id, :foreign_key => :parent_id, :order => configuration[:order]}, &b
          belongs_to :root, :class_name => name, :foreign_key => :root_id
          scope :roots, :order => configuration[:order], :conditions => {:parent_id => nil}
          after_create       :assign_csv_ids
          after_validation  :update_csv_ids, :on => :update

          instance_eval do
            include ActiveRecord::Acts::BetterTree::InstanceMethods

            def root(options = {})
              roots(options).first
            end

            def traverse(nodes = self.roots, &block)
              nodes.each do |node|
                yield node
                traverse(node.children, &block)
              end
            end

            # Call this to upgrade an existing acts_as_tree to acts_as_better_tree
            def build_csv_ids!(nodes = self.roots)
              transaction do
                traverse(nodes) do |node|
                  node.csv_ids = node.build_csv_ids
                  node.save
                end
              end
            end
          end
        end
      end

      module InstanceMethods
        def parent_foreign_key_changed?
          parent_id_changed?
        end

        def ancestors
          if self.csv_ids
            ids = self.csv_ids.split(',')[0...-1]
            (@ancestors ||= self.class.where(:id => ids).order('csv_ids ASC'))
          else
            node, nodes = self, []
            nodes << node = node.parent while node.parent
            (@ancestors ||= nodes.reverse)
          end
        end

        def self_and_ancestors
          ancestors + [self]
        end

        def self_and_children
          [self] + children
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
          return self.class.where(:parent_id => self.id).first.blank?
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

        def to_csv(nodes = self.children)
          csv = []
          nodes.each do |node|
            if node.childless?
              csv += [node.self_and_ancestors.map(&:name).join(",")]
            else
              csv += [to_csv(node.children)]
            end
          end
          return csv.join("\n")
        end

        def build_csv_ids
          self.parent_id.blank? ? self.id.to_s : "#{self.parent.csv_ids},#{self.id}"
        end

        protected

        def csv_id_like_pattern(prefix = nil)
          (prefix || self.csv_ids) + ',%'
        end

        def build_root_id
          return (self.parent_id ? self.parent.root_id : self.id)
        end

        def find_all_children_with_csv_ids(prefix = nil, options = {})
          conditions = [self.class.send(:sanitize_sql, ['csv_ids LIKE ?', csv_id_like_pattern(prefix)])]
          conditions << "(#{self.class.send(:sanitize_sql, options[:conditions])})" unless options[:conditions].blank?
          options.update(:conditions => conditions.join(" AND "))
          self.class.find(:all, options)
        end

        def assign_csv_ids
          self.update_attributes(:csv_ids => build_csv_ids, :root_id => build_root_id)
        end

        def update_csv_ids
          return unless parent_foreign_key_changed?
          old_csv_ids = self.csv_ids
          self.csv_ids = build_csv_ids
          self.root_id = build_root_id
          self.class.update_all("csv_ids = Replace(csv_ids, '#{old_csv_ids},', '#{self.csv_ids},'), root_id = #{self.root_id}", "csv_ids like '#{old_csv_ids},%'")
        end
      end
    end
  end
end

#ActiveRecord::Base.send :include, ActiveRecord::Acts::BetterTree
#
#ActiveRecord::Base.class_eval do
#  include ActiveRecord::Acts::BetterTree
#end

class ActiveRecord::Base
  include ActiveRecord::Acts::BetterTree
end
