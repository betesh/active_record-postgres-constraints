# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'active_record/postgres/constraints/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'active_record-postgres-constraints'
  s.version = ActiveRecord::Postgres::Constraints::VERSION
  s.authors = ['Isaac Betesh']
  s.email = ['ibetesh@on-site.com']
  s.homepage = 'https://github.com/on-site/active_record-postgres-constraints'
  s.summary = 'Store your constraints in db/schema.rb'
  s.description = %(
    From http://edgeguides.rubyonrails.org/active_record_migrations.html#types-of-schema-dumps:

      There is however a trade-off: db/schema.rb cannot express database
      specific items such as triggers, stored procedures or check constraints.
      While in a migration you can execute custom SQL statements, the schema
      dumper cannot reconstitute those statements from the database. If you are
      using features like this, then you should set the schema format to :sql.

    No longer is this the case.  You can now use the default schema format
    (:ruby) and still preserve your check constraints.
  )

  s.license = 'MIT'

  s.files = Dir[
    '{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md'
  ]

  s.add_dependency 'pg'
  s.add_dependency 'rails', '>= 5.0', '<= 7.0'

  s.add_development_dependency 'osm-rubocop', '= 0.1.15'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rspec-rails'
end
