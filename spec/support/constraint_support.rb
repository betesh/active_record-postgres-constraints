# frozen_string_literal: true

require_relative 'shared_migration_methods'

module ConstraintSupport
  include SharedMigrationMethods

  extend RSpec::SharedContext
  extend RSpec::Matchers::DSL

  before do
    stub_const(model_class, Class.new(ApplicationRecord))

    cleanup_database

    generate_migration('20170101120000', Random.rand(1..1000)) do
      content_of_change_method
    end

    run_migrations
  end

  after do
    rollback
    delete_all_migration_files
  end

  after(:all) do
    cleanup_database
    dump_schema
  end

  matcher :include_the_constraint_in_the_schema_file do
    match do
      schema = File.read(schema_file)
      expect(schema).to match(expected_schema_regex)
    end
  end

  def rails_gte_5_1_0?
    Gem::Version.new(ActiveRecord.gem_version) >= Gem::Version.new('5.1.0')
  end

  def create_table_line_of_schema_file(table_name)
    "create_table \"#{table_name}\", #{'id: :serial, ' if rails_gte_5_1_0?}force: :cascade do |t|"
  end
end

RSpec.configure do |config|
  config.include ConstraintSupport, constraint: true
end
