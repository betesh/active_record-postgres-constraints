# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module TableDefinition
        attr_reader :constraints

        CONSTRAINT_TYPES.keys.each do |type|
          define_method "#{type}_constraint" do |name_or_conditions, conditions = nil|
            add_constraint(type, name_or_conditions, conditions)
          end
        end

        def add_constraint(type, name_or_conditions, conditions)
          @constraints ||= []
          constraint =
            ActiveRecord::Postgres::Constraints.
              class_for_constraint_type(type).
              to_sql(name, name_or_conditions, conditions)
          constraints << constraint
        end
      end
    end
  end
end
