# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module SchemaCreation
        # rubocop:disable Style/MethodName
        def visit_TableDefinition(o)
          # rubocop:enable Style/MethodName
          result = super
          return result unless o.check_constraints

          nesting = 0
          # Find the closing paren of the "CREATE TABLE ( ... )" clause
          index = result.length.times do |i|
            token = result[i]
            nesting, should_break = adjust_nesting(nesting, token)
            break i if should_break
          end
          result[index] = ", #{o.check_constraints.join(', ')})"
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
