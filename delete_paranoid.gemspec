# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "delete_paranoid/version"

Gem::Specification.new do |s|
  s.name        = "delete_paranoid"
  s.version     = DeleteParanoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan Sonnek", "developers@socialcast.com"]
  s.email       = ["developers@socialcast.com"]
  s.homepage    = "http://github.com/socialcast/delete_paranoid"
  s.summary     = %q{soft delete Rails ActiveRecord objects}
  s.description = %q{flag database records as deleted and hide them from subsequent queries}

  s.rubyforge_project = "delete_paranoid"

  s.add_runtime_dependency(%q<activerecord>, [">= 4.2.7.1"])
  s.add_development_dependency(%q<rspec>, [">= 3.5"])
  s.add_development_dependency(%q<bundler>, [">= 0"])
  s.add_development_dependency(%q<sqlite3-ruby>, ["~> 1.3.2"])
  s.add_development_dependency(%q<rake>, [">= 0.9.2.2"])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
