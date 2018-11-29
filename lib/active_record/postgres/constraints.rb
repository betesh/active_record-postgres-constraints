# frozen_string_literal: true

require_relative 'constraints/command_recorder'
require_relative 'constraints/postgresql_adapter'
require_relative 'constraints/railtie'
require_relative 'constraints/schema_creation'
require_relative 'constraints/schema_dumper'
require_relative 'constraints/table_definition'
require_relative 'constraints/version'

module ActiveRecord
  module Postgres
    module Constraints
      class << self
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

        def to_sql(table, name_or_conditions, conditions = nil)
          if conditions
            name = name_or_conditions
          else
            name = "#{table}_#{Time.zone.now.nsec}"
            conditions = name_or_conditions
          end

          "CONSTRAINT #{name} CHECK (#{normalize_conditions(conditions)})"
        end
      end
    end
  end
end
