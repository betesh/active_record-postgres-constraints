# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module TableDefinition
        attr_reader :constraints

        def check_constraint(name_or_conditions, conditions = nil)
          @constraints ||= []
          constraint =
            ActiveRecord::Postgres::Constraints.
              class_for_constraint_type(:check).
              to_sql(name, name_or_conditions, conditions)
          constraints << constraint
        end
      end
    end
  end
end
