# ActsAsBetterTree

acts_as_better_tree is great for anyone who needs a fast tree capable of handling millions of nodes without slowing down on writes like nestedset or on reads like a standard tree.
It is backwards compatible with acts_as_tree and remains fast with large datasets by storing the ancestry of every node in the field csv_ids.


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

    If upgrading from acts_as_tree just add root_id and csv_ids and run Category.build_csv_ids!

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

Copyright (c) 2008 Isaac Sloan, released under the MIT license
Inspired by David Heinemeier Hansson's acts_as_tree

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
