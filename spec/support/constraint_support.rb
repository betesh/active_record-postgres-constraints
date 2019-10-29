# frozen_string_literal: true

require_relative 'shared_migration_methods'

module ConstraintSupport
  include SharedMigrationMethods

  extend RSpec::SharedContext
  extend RSpec::Matchers::DSL

  before(:all) do
    FileUtils.mkdir_p(migration_dir)

    unless defined?(ActiveRecord::Base.connection.migration_context)
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths = migration_dir
    end
  end

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
    def schema_file_offset
      17
    end

    def schema
      @schema ||= File.read(schema_file).split("\n")
    end

    def expected_lines
      @expected_lines ||= expected_schema.strip_heredoc.indent(2).split("\n")
    end

    match do
      expected_lines.each_with_index do |line, i|
        expect(schema[i + schema_file_offset]).to match(/\A#{line}\z/)
      end
    end

    failure_message do
      i = -1
      line_not_found = expected_lines.find do |line|
        i += 1
        !schema[i + schema_file_offset].match(/\A#{line}\z/)
      end
      schema_file_line = schema_file_offset + i
      "Expected line #{schema_file_line} of schema.rb to match:\n" \
        "#{line_not_found}\nbut it was:\n#{schema[schema_file_line]}"
    end
  end

  def rails_gte_5_1_0?
    Gem::Version.new(ActiveRecord.gem_version) >= Gem::Version.new('5.1.0')
  end

  def create_table_line_of_schema_file(table_name)
    "create_table \"#{table_name}\", #{'id: :serial, ' if rails_gte_5_1_0?}force: :cascade do \|t\|"
  end
end

RSpec.configure do |config|
  config.include ConstraintSupport, constraint: true
end
