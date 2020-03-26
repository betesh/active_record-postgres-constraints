# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module Types
        module Check
          class << self
            def to_sql(table, name_or_conditions, conditions = nil)
              name, conditions = ActiveRecord::Postgres::Constraints.
                normalize_name_and_conditions(table, name_or_conditions, conditions)
              "CONSTRAINT #{name} CHECK (#{normalize_conditions(conditions)})"
            end

            def to_schema_dump(constraint)
              name = constraint['conname']
              conditions = constraint['definition'].gsub(/^CHECK\s*\((.*)\)\s*$/, '\\1')
              "    t.check_constraint :#{name}, #{conditions.inspect}"
            end

            def example_constraint
              "'price > 999'"
            end

            private

            def normalize_conditions(conditions)
              conditions = [conditions] unless conditions.is_a?(Array)
              conditions = conditions.map do |condition|
                if condition.is_a?(Hash)
                  normalize_conditions_hash(condition)
                else
                  condition
                end
              end

              return conditions.first if 1 == conditions.length

              "(#{conditions.join(') AND (')})"
            end

            def normalize_conditions_hash(hash)
              hash = hash.reduce([]) do |array, (column, predicate)|
                predicate = predicate.join("', '") if predicate.is_a?(Array)
                array << "#{column} IN ('#{predicate}')"
              end
              "(#{hash.join(') AND (')})"
            end
          end
        end
      end
    end
  end
end
