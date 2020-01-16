# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module SchemaDumper
        def indexes_in_create(table, stream)
          constraints = @connection.constraints(table)
          indexes = @connection.indexes(table).reject do |index|
            constraints.pluck('conname').include?(index_name(index))
          end
          dump_indexes(indexes, stream)
          dump_constraints(constraints, stream)
        end

        private

        def dump_indexes(indexes, stream)
          return unless indexes.any?

          index_statements = indexes.map do |index|
            "    t.index #{index_parts(index).join(', ')}"
          end
          stream.puts index_statements.sort.join("\n")
        end

        def dump_constraints(constraints, stream)
          return unless constraints.any?

          constraint_statements = constraints.map do |constraint|
            type = CONSTRAINT_TYPES.key(constraint['contype'])
            ActiveRecord::Postgres::Constraints.
              class_for_constraint_type(type).
              to_schema_dump(constraint)
          end
          stream.puts constraint_statements.sort.join("\n")
        end

        def index_name(index)
          if index.is_a?(ActiveRecord::ConnectionAdapters::IndexDefinition)
            index.name
          else
            index['name']
          end
        end
      end
    end
  end
end
