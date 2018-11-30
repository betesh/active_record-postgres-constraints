# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module PostgreSQLAdapter
        CONSTRAINT_TYPES.keys.each do |type|
          define_method "add_#{type}_constraint" do |table, n_or_c, c = nil|
            add_constraint(type, table, n_or_c, c)
          end

          define_method "remove_#{type}_constraint" do |table, name, c = nil|
            remove_constraint(type, table, name, c)
          end
        end

        def add_constraint(type, table, name_or_conditions, conditions)
          constraint =
            ActiveRecord::Postgres::Constraints.
              class_for_constraint_type(type).
              to_sql(table, name_or_conditions, conditions)
          execute("ALTER TABLE #{table} ADD #{constraint}")
        end

        def remove_constraint(_type, table, name, _conditions)
          execute("ALTER TABLE #{table} DROP CONSTRAINT #{name}")
        end

        def constraints(table)
          types = CONSTRAINT_TYPES.values.map { |v| "'#{v}'" }.join(', ')
          sql = "SELECT conname, consrc, contype
            FROM pg_constraint
            JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
            WHERE
              pg_constraint.contype IN (#{types})
              AND
              pg_class.relname = '#{table}'".tr("\n", ' ').squeeze(' ')
          execute sql
        end
      end
    end
  end
end
