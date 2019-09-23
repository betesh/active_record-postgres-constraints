# frozen_string_literal: true

module SharedMigrationMethods
  def dummy_dir
    File.expand_path('../../dummy', __FILE__)
  end

  def migration_dir
    "#{dummy_dir}/db/migrate#{ENV['TEST_ENV_NUMBER']}"
  end

  def delete_all_migration_files
    `rm -rf #{migration_dir}/*.rb`
  end

  def cleanup_database
    delete_all_migration_files
    ActiveRecord::Tasks::DatabaseTasks.drop_current
    ActiveRecord::Tasks::DatabaseTasks.create_current
  end

  def migration_file(migration_number, suffix)
    migration_file_name = "#{migration_number}_migration_#{suffix}"
    "#{migration_dir}/#{migration_file_name}.rb"
  end

  def migration_content(migration_name_suffix)
    <<-MIGRATION_CLASS.strip_heredoc
    class Migration#{migration_name_suffix} < ActiveRecord::Migration[5.0]
      self.verbose = false
      def change\n#{yield.strip_heredoc.indent(10).rstrip}
      end
    end
    MIGRATION_CLASS
  end

  def generate_migration(migration_number, suffix, &block)
    File.open(migration_file(migration_number, suffix), 'w') do |f|
      f.puts migration_content(suffix, &block)
    end
  end

  def schema_file
    "#{dummy_dir}/db/schema.rb"
  end

  def dump_schema
    require 'active_record/schema_dumper'
    File.open(schema_file, 'w:utf-8') do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  def run_migrations
    if defined?(ActiveRecord::Base.connection.migration_context)
      ActiveRecord::Base.connection.migration_context.migrate
    else
      ActiveRecord::Tasks::DatabaseTasks.migrate
    end
    dump_schema
  end

  def rollback
    if defined?(ActiveRecord::MigrationContext)
      ActiveRecord::Base.connection.migration_context.rollback(1)
    else
      ActiveRecord::Migrator.rollback(
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths, 1
      )
    end
    dump_schema
  end

  # Taken from https://github.com/ged/ruby-pg/blob/v1.1.4/spec/helpers.rb#L338
  def wait_for_async_pg_commands_to_finish
    conn = ActiveRecord::Base.connection.raw_connection
    loop do
      conn.consume_input
      while conn.is_busy
        select([conn.socket_io], nil, nil, 5.0) || raise('Timeout waiting for query response.')
        conn.consume_input
      end
      break unless conn.get_result
    end
  end
end
