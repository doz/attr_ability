# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "attr_ability/version"

Gem::Specification.new do |s|
  s.name        = "attr_ability"
  s.version     = AttrAbility::VERSION
  s.authors     = ["Alexander Danilenko"]
  s.email       = ["alexander@danilenko.org"]
  s.homepage    = "https://github.com/doz/attr_ability"
  s.summary     = %q{Mass assignment security based on CanCan abilities.}
  s.description = %q{Associates CanCan configuration with ActiveRecord attributes, and secures model form mass assignment based on current ability.}

  s.rubyforge_project = "attr_ability"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "with_model", '~> 0.1.5'
  s.add_development_dependency "rails", '~> 3.1.0'
  s.add_dependency "cancan"
end
