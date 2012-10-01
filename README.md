# ActsAsBetterTree

An alternative to nested_sets and acts_as_tree. Designed to be a drop in replacement for acts_as_tree. Replaces betternestedset without the slow inserts when dealing with a large dataset. Used by upillar.com on a dataset of over 900,000 categories with no slow downs. In tests it shows a 285% speed increase on inserts with a dataset of 100k categories. As datasets become larger its insert speed stays about the same when nested_sets become slower. In all of my tests read speeds have been comparable with nested sets on everything but all_children which is inperceptibly slower on a dataset of 100k than betternestedset.


## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_better_tree'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_better_tree

## Usage

  Required fields are parent_id, root_id, csv_ids.

    create_table :categories do |t|
     t.column :root_id, :integer
     t.column :parent_id, :integer
     t.column :csv_ids, :string
     t.column :name, :string
    end

  If upgrading from acts_as_tree just add root_id and csv_ids and run Category.tree_to_better_tree!

    class Category < ActiveRecord::Base
        acts_as_better_tree :order => "name"
    end

    Example:
    root
    \_ child1
        \_ subchild1
        \_ subchild2

    root      = Category.create("name" => "root")
    child1    = root.children.create("name" => "child1")
    subchild1 = child1.children.create("name" => "subchild1")

    root.parent   # => nil
    child1.parent # => root
    root.children # => [child1]
    root.children.first.children.first # => subchild1
    child1.self_and_ancestors # => [root, child1]
    child1.ancestors
    child1.siblings
    child1.self_and_siblings
    child1.move_to_child_of(parent)
    child1.childless?
    child1.ancestor_of?(subchild1)
    child1.descendant_of?(root)
    root.to_csv # => "root,child1,subchild1\n" returns and array of all children
    Category.to_csv # => "root,child1,subchild1\nroot,child1,subchild2\n" returns entire tree in a csv string


Copyright (c) 2008 Isaac Sloan, released under the MIT license.
Inspired by David Heinemeier Hansson's acts_as_tree

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
