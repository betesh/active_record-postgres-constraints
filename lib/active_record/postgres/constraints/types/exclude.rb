# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module Types
        module Exclude
          OPERATOR_SYMBOLS = {
            equals: '=',
            overlaps: '&&',
          }.freeze

          class << self
            def to_sql(table, name_or_conditions, conditions = nil)
              name, conditions = ActiveRecord::Postgres::Constraints.
                normalize_name_and_conditions(table, name_or_conditions, conditions)

              using = conditions.delete(:using)
              using = " USING #{using}" if using

              where = conditions.delete(:where)
              where = " WHERE (#{where})" if where

              conditions = normalize_conditions(conditions).join(', ')

              "CONSTRAINT #{name} EXCLUDE#{using} (#{conditions})#{where}"
            end

            def to_schema_dump(constraint)
              name = constraint['conname']
              definition = constraint['definition']

              using = definition.match(/USING (\w*)/).try(:[], 1)
              using = "using: :#{using}, " if using

              where = definition.match(/WHERE \((.*)\)/).try(:[], 1)
              where = "where: '#{where}'" if where

              exclusions = definition_to_exclusions(definition).join(', ')
              conditions = "#{using}#{exclusions}#{", #{where}" if where}"

              "    t.exclude_constraint :#{name}, #{conditions}"
            end

            def example_constraint
              %(using: :gist, 'tsrange("from", "to")' => :overlaps, project_id: :equals)
            end

            private

            def definition_to_exclusions(definition)
              definition.
                split(' WHERE')[0].
                match(/\((.*)/)[1].
                chomp(')').
                scan(/((?:[^,(]+|(?:\((?>[^()]+|\g<-1>)*\)))+)/).
                flatten.
                map! { |exclusion| element_and_operator(exclusion) }
            end

            def element_and_operator(exclusion)
              element, operator = exclusion.strip.split(' WITH ')
              "#{normalize_element(element)} #{normalize_operator(operator)}"
            end

            def normalize_conditions(conditions)
              conditions.map do |element, operator|
                "#{element} WITH #{OPERATOR_SYMBOLS[operator.to_sym]}"
              end
            end

            def normalize_element(element)
              element.include?('(') ? "'#{element}' =>" : "#{element}:"
            end

            def normalize_operator(operator)
              ":#{OPERATOR_SYMBOLS.invert[operator]}"
            end
          end
        end
      end
    end
  end
end
