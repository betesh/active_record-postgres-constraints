# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module PostgreSQLAdapter
        def add_check_constraint(table, name_or_conditions, conditions = nil)
          constraint = Constraints.to_sql(table, name_or_conditions, conditions)
          execute("ALTER TABLE #{table} ADD #{constraint}")
        end

        def remove_check_constraint(table, name, _conditions = nil)
          execute("ALTER TABLE #{table} DROP CONSTRAINT #{name}")
        end

        def constraints(table)
          sql = "SELECT conname, consrc
            FROM pg_constraint
            JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
            WHERE
              pg_constraint.contype = 'c'
              AND
              pg_class.relname = '#{table}'".tr("\n", ' ').squeeze(' ')
          execute sql
        end
      end
    end
  end
end
