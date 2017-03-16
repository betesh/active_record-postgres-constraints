# frozen_string_literal: true
module ActiveRecord
  module Postgres
    module Constraints
      module CommandRecorder
        def add_check_constraint(*args, &block)
          record(:add_check_constraint, args, &block)
        end

        def invert_add_check_constraint(args, &block)
          [:remove_check_constraint, args, block]
        end

        def remove_check_constraint(*args, &block)
          if args.length < 3
            raise ActiveRecord::IrreversibleMigration,
              'To make this migration reversible, pass the constraint to '\
              'remove_check_constraint, i.e. `remove_check_constraint, '\
              "#{args[0].inspect}, #{args[1].inspect}, 'price > 999'`"
          end
          record(:remove_check_constraint, args, &block)
        end

        def invert_remove_check_constraint(args, &block)
          [:add_check_constraint, args, block]
        end
      end
    end
  end
end
