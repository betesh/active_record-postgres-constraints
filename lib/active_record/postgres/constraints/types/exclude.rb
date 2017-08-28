# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module Types
        module Exclude
          class << self
            def to_sql(table, name_or_conditions, conditions = nil)
              if conditions
                name = name_or_conditions
              else
                name = "#{table}_#{Time.zone.now.nsec}"
                conditions = name_or_conditions
              end
              using = "USING #{conditions[:using]} " if conditions[:using]
              w = " WHERE (#{conditions[:where]})" if conditions[:where]
              "CONSTRAINT #{name} EXCLUDE #{using}"\
              "(#{normalize_conditions(conditions.except(:using, :where))})#{w}"
            end

            def to_method(constraint)
              name = constraint['conname']
              definition = constraint['definition']
              using_type = definition.match(/USING (\w*)/).try(:[], 1)
              using = "using: :#{using_type}, " if using_type
              where_clause = definition.match(/WHERE \((.*)\)/).try(:[], 1)
              where = ", where: '#{where_clause}'" if where_clause
              exclusions =
                definition_to_exclusions(definition).
                  join(', ')
              "    t.exclude_constraint :#{name}, #{using}#{exclusions}#{where}"
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
              hash = conditions.reduce([]) do |array, (element, operator)|
                array << "#{element} WITH #{OPERATOR_SYMBOLS[operator.to_sym]}"
              end
              hash.join(', ')
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
