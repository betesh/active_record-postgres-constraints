# frozen_string_literal: true
module ActiveRecord
  module Postgres
    module Constraints
      module TableDefinition
        attr_reader :check_constraints

        def check_constraint(name_or_conditions, conditions = nil)
          @check_constraints ||= []
          constraint = Constraints.to_sql(name, name_or_conditions, conditions)
          check_constraints << constraint
        end
      end
    end
  end
end
