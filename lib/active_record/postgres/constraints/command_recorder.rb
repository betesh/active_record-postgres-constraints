# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      module CommandRecorder
        CONSTRAINT_TYPES.keys.each do |type|
          define_method("add_#{type}_constraint") do |*args, &block|
            record(:"add_#{type}_constraint", args, &block)
          end

          define_method("invert_add_#{type}_constraint") do |args, &block|
            [:"remove_#{type}_constraint", args, block]
          end

          define_method("remove_#{type}_constraint") do |*args, &block|
            if args.length < 3
              example_constraint = ActiveRecord::Postgres::Constraints.
                class_for_constraint_type(type).
                example_constraint

              raise ActiveRecord::IrreversibleMigration,
                'To make this migration reversible, pass the constraint to '\
                "remove_#{type}_constraint, i.e. `remove_#{type}_constraint "\
                "#{args[0].inspect}, #{args[1].inspect}, #{example_constraint}`"
            end
            record(:"remove_#{type}_constraint", args, &block)
          end

          define_method("invert_remove_#{type}_constraint") do |args, &block|
            [:"add_#{type}_constraint", args, block]
          end
        end
      end
    end
  end
end
