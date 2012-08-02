# -*- encoding: utf-8 -*-
require File.expand_path('../lib/acts_as_better_tree/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Isaac Sloan"]
  gem.email         = ["isaac@isaacsloan.com"]
  gem.description   = %q{acts_as_better_tree is great for anyone who needs a fast tree capable of handling millions of nodes without slowing down on writes like nestedset or on reads like a standard tree.}
  gem.summary       = %q{acts_as_better_tree is backwards compatible with acts_as_tree and remains fast with large datasets by storing the ancestry of every node in the field csv_ids.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "acts_as_better_tree"
  gem.require_paths = ["lib"]
  gem.version       = ActsAsBetterTree::VERSION
end
