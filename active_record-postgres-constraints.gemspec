$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_record/postgres/constraints/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_record-postgres-constraints"
  s.version     = ActiveRecord::Postgres::Constraints::VERSION
  s.authors     = ["Isaac Betesh"]
  s.email       = ["ibetesh@on-site.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ActiveRecord::Postgres::Constraints."
  s.description = "TODO: Description of ActiveRecord::Postgres::Constraints."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.2"

  s.add_development_dependency "sqlite3"
end
