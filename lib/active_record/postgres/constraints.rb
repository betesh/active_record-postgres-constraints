# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      CONSTRAINT_TYPES = {
        check: 'c',
        exclude: 'x',
      }.freeze
      OPERATOR_SYMBOLS = {
        equals: '=',
        overlaps: '&&',
      }.freeze

      module_function

      def class_for_constraint_type(type)
        'ActiveRecord::Postgres::Constraints::Types::'\
        "#{type.to_s.classify}".constantize
      end
    end
  end
end

require_relative 'constraints/types/check'
require_relative 'constraints/types/exclude'
require_relative 'constraints/command_recorder'
require_relative 'constraints/postgresql_adapter'
require_relative 'constraints/railtie'
require_relative 'constraints/schema_creation'
require_relative 'constraints/schema_dumper'
require_relative 'constraints/table_definition'
require_relative 'constraints/version'
