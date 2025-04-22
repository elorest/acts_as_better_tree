require 'spec_helper'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :categories do |t|
      t.column :root_id, :integer
      t.column :parent_id, :integer
      t.column :csv_ids, :string
      t.column :name, :string
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Category < ActiveRecord::Base
  acts_as_better_tree
end

describe "ActsAsBetterTree" do
  before :all do
    teardown_db
    setup_db
    Category.create(name: "Animals")
  end

  describe "#roots" do
    it "should find at least one root" do
      Category.roots.size.should >= 1
    end
  end

  it "should make node child of parent" do
    cat = Category.create(:name => "Cats", :parent_id => Category.roots.first.id)
    lion = Category.create(:name => "Lions")
    lion.move_to_child_of(cat)
    lion.parent.should eql cat
  end

  it "returns children of node" do
    cats = Category.find_by_name("Cats")
    Category.create(:name => "Tiger", :parent => cats)
    Category.create(:name => "House Cat", :parent => cats)
    Category.create(:name => "Panther", :parent => cats)
    cats.children.count.should eql 4
  end

  it "returns self and ancestors" do
    tiger = Category.find_by_name("Tiger")
    tiger.self_and_ancestors.map(&:name).should eql ["Animals", "Cats", "Tiger"]
  end

  it "returns self and siblings" do
    tiger = Category.find_by_name("Tiger")
    tiger.self_and_siblings.map(&:name).should eql ["Lions", "Tiger", "House Cat", "Panther"]
  end

  it "creates a node as child of parent" do
    cats = Category.find_by_name("Cats")
    bobcats = cats.children.create(:name => "Bobcats")
    bobcats.parent.name.should eql "Cats"
  end

  it "should return a csv string of all nodes" do
    Category.to_csv.should eql "Animals,Cats,Lions\nAnimals,Cats,Tiger\nAnimals,Cats,House Cat\nAnimals,Cats,Panther\nAnimals,Cats,Bobcats\n"
  end

  context "when there are multiple category roots" do
    before do
      baseball = Category.create(name: "baseball")
      basketball = Category.create(name: "basketball")
      football = Category.create(name: "football")
      Category.create(name: "minor", :parent => baseball)
      Category.create(name: "major", :parent => baseball)
      Category.create(name: "minor", :parent => basketball)
      Category.create(name: "major", :parent => basketball)
      Category.create(name: "minor", :parent => football)
      Category.create(name: "major", :parent => football)

    end
    context "and the category root is deleted" do
      it "should also remove its children" do
        category = Category.find_by_name("football")
        category.children.count.should eql 2
        category.destroy

        Category.find_by_name("football").should eql nil
        Category.find_by_name("basketball").children.should_not eql nil
        Category.find_by_name("baseball").children.should_not eql nil
      end
    end

    context "and a non category root is deleted" do
      it "should remove only its children" do
        category = Category.find_by_name("football")
        minor = category.children.find_by_name("minor")
        minor.children.create(:name => "topps")

        minor.destroy
        category.children.find_by_name("minor").should eql nil
        Category.find_by_name("basketball").children.should_not eql nil
        Category.find_by_name("baseball").children.should_not eql nil
      end
    end
  end
end
