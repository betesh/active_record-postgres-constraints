# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module SchemaCreation
        # rubocop:disable Naming/MethodName
        def visit_TableDefinition(table_definition)
          # rubocop:enable Naming/MethodName
          result = super
          return result unless table_definition.check_constraints

          nesting = 0
          # Find the closing paren of the "CREATE TABLE ( ... )" clause
          index = result.length.times do |i|
            token = result[i]
            nesting, should_break = adjust_nesting(nesting, token)
            break i if should_break
          end
          result[index] = ", #{table_definition.check_constraints.join(', ')})"
          result
        end

        def adjust_nesting(nesting, token)
          nesting_was = nesting
          nesting += 1 if '(' == token
          nesting -= 1 if ')' == token
          [nesting, (1 == nesting_was && nesting.zero?)]
        end
      end
    end
  end
end
