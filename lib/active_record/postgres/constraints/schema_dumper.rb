# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module SchemaDumper
        def indexes_in_create(table, stream)
          super
          constraints = @connection.constraints(table)
          return unless constraints.any?

          constraint_statements = constraints.map do |constraint|
            type = CONSTRAINT_TYPES.key(constraint['contype'])
            ActiveRecord::Postgres::Constraints.
              class_for_constraint_type(type).
              to_method(constraint)
          end
          stream.puts constraint_statements.sort.join("\n")
        end
      end
    end
  end
end
