Gem::Specification.new do |s|
  s.name        = "tiny_explorer"
  s.version     = "1.0.0"
  s.description = 'a pipeable and interactive log file explorer'
  s.summary     = "want a powerful in-memory log file explorer that's super configurable? then this library is for you"
  s.authors     = ["Jeff Lunt"]
  s.email       = "jefflunt@gmail.com"
  s.files       = ["lib/tiny_explorer.rb"]
  s.homepage    = "https://github.com/jefflunt/tiny_explorer"
  s.license     = "MIT"
  s.add_runtime_dependency "tiny_dot", [">= 0"]
end
