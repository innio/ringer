# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ringer/version"

Gem::Specification.new do |s|
  s.name        = "ringer"
  s.version     = Ringer::VERSION
  s.authors     = ["Brian Michalski"]
  s.email       = ["bmichalski@gmail.com"]
  s.homepage    = "https://github.com/innio/ringer"
  s.summary     = %q{Interface to the Wyless API}
  s.description = %q{Provision cellular devices}

  s.rubyforge_project = "ringer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
