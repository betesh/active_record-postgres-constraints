# frozen_string_literal: true

require 'rails_helper'
require 'shared_migration_methods'

RSpec.describe ActiveRecord::Postgres::Constraints::Types::Exclude do
  context 'when a migration adds an exclude constraint' do
    include SharedMigrationMethods

    class ApplicationRecord < ActiveRecord::Base; self.abstract_class = true; end
    class Price < ApplicationRecord; end

    before do
      ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      cleanup_database

      generate_migration('20170101120000', Random.rand(1..1000)) do
        content_of_change_method
      end

      run_migrations
    end

    after do
      rollback
      delete_all_migration_files
    end

    # rubocop:disable RSpec/BeforeAfterAll
    after(:all) do
      # rubocop:enable RSpec/BeforeAfterAll
      cleanup_database
      dump_schema
    end

    shared_examples_for 'adds a constraint' do
      let(:expected_schema_regex) do
        Regexp.escape <<-MIGRATION.strip_heredoc.indent(2)
          create_table "prices", #{'id: :serial, ' if Gem::Version.new(ActiveRecord.gem_version) >= Gem::Version.new('5.1.0')}force: :cascade do |t|
            t.integer #{' ' if Gem::Version.new(ActiveRecord.gem_version) < Gem::Version.new('5.1.0')}"price"
            t.datetime "from"
            t.datetime "to"
            t.exclude_constraint :test_constraint, #{expected_constraint_string}
          end
        MIGRATION
      end

      it 'includes the constraint in the schema file' do
        schema = File.read(schema_file)
        expect(schema).to match expected_schema_regex
      end

      it 'enforces the constraint' do # rubocop:disable RSpec/ExampleLength
        create_price = ->(from, to, price = 999) { Price.create! price: price, from: from, to: to }

        create_price.call(1.day.ago, 1.day.from_now)
        expect { create_price.call(Time.current, 2.days.from_now) }.to(
          raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
        )
        create_price.call(2.days.from_now, nil)
        create_price.call(Time.current, 2.days.from_now, 1)
        if where_clause
          create_price.call(Time.current, 2.days.from_now, 1)
        else
          expect { create_price.call(Time.current, 2.days.from_now, 1) }.to(
            raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
          )
        end
      end
    end

    let(:where_clause) { false }

    let(:expected_constraint_error_message) do
      'PG::ExclusionViolation: ERROR:  conflicting key value violates '\
      'exclusion constraint "test_constraint"'
    end

    let(:expected_error_regex) { /\A#{expected_constraint_error_message}/ }

    context 'when using `t.exclude_constraint`' do
      let(:content_of_change_method) do
        <<-MIGRATION
          enable_extension "btree_gist"
          create_table :prices do |t|
            t.integer  :price
            t.datetime :from
            t.datetime :to
            t.exclude_constraint :test_constraint, #{constraint}
          end
        MIGRATION
      end

      context 'when the constraint is a String' do
        let(:constraint) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          ':price => :equals'
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          'price: :equals'
        end

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            ':price => :equals, where: \'price <> 1\''
          end
          let(:expected_constraint_string) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'price: :equals, where: \'(price <> 1)\''
          end

          it_behaves_like 'adds a constraint'
        end

        context 'when the constraint is anonymous' do
          let(:content_of_change_method) do
            <<-MIGRATION
              enable_extension "btree_gist"
              create_table :prices do |t|
                t.integer  :price
                t.datetime :from
                t.datetime :to
                t.exclude_constraint   #{constraint}
              end
            MIGRATION
          end

          let(:expected_constraint_error_message) do
            'PG::ExclusionViolation: ERROR:  conflicting key value violates '\
            'exclusion constraint "prices_[0-9]{9}"'
          end

          it_behaves_like 'adds a constraint' do
            let(:expected_schema_regex) do
              Regexp.new <<-MIGRATION.strip_heredoc.indent(2)
                create_table "prices", force: :cascade do \|t\|
                  t.integer  #{' ' if Gem::Version.new(ActiveRecord.gem_version) < Gem::Version.new('5.1.0')}"price"
                  t.datetime "from"
                  t.datetime "to"
                  t.exclude_constraint :prices_[0-9]{7-9}, #{expected_constraint_string}
                end
              MIGRATION
            end
          end
        end
      end

      context 'when the constraint is a Hash' do
        let(:constraint) do
          { using: :gist, 'tsrange("from", "to")' => :overlaps, price: :equals }
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          'price: :equals'
        end

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) do
            {
              using: :gist,
              'tsrange("from", "to")' => :overlaps,
              price: :equals,
              where: 'price <> 1',
            }
          end
          let(:expected_constraint_string) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'price: :equals, where: \'(price <> 1)\''
          end

          it_behaves_like 'adds a constraint'
        end
      end
    end

    context 'when using add_exclude_constraint' do
      let(:constraint) do
        { using: :gist, 'tsrange("from", "to")' => :overlaps, price: :equals }
      end
      let(:expected_constraint_string) do
        'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
        'price: :equals'
      end
      let(:content_of_change_method) do
        <<-MIGRATION
          enable_extension "btree_gist"
          create_table :prices do |t|
            t.integer  :price
            t.datetime :from
            t.datetime :to
          end
          add_exclude_constraint :prices, :test_constraint, #{constraint}
        MIGRATION
      end

      it_behaves_like 'adds a constraint'

      context 'when a where clause is present' do
        let(:where_clause) { true }
        let(:constraint) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            ':price => :equals, where: \'price <> 1\''
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'price: :equals, where: \'(price <> 1)\''
        end

        it_behaves_like 'adds a constraint'
      end

      context 'when the constraint is removed in a later migration' do
        let(:content_of_change_method_for_removing_migration) do
          "remove_exclude_constraint :prices, :test_constraint, #{constraint}"
        end

        before do
          generate_migration('20170201120000', Random.rand(1001..2000)) do
            content_of_change_method_for_removing_migration
          end

          run_migrations
        end

        it 'removes the constraint from the schema file' do
          schema = File.read(schema_file)
          expect(schema).not_to match(/exclude_constraint/)
        end

        it 'enforces the constraint' do # rubocop:disable RSpec/ExampleLength
          create_price = ->(from, to) { Price.create! price: 999, from: from, to: to }

          create_price.call(Time.current, 2.days.from_now)
          expect { create_price.call(1.day.ago, 1.day.from_now) }.not_to(raise_error)

          # Ensure that we can safely roll back the migration that removed the
          # exclude constraint
          Price.destroy_all

          rollback

          create_price.call(Time.current, 2.days.from_now)
          expect { create_price.call(1.day.ago, 1.day.from_now) }.to(
            raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
          )
        end

        context 'when remove_exclude_constraint is irreversible' do
          let(:content_of_change_method_for_removing_migration) do
            'remove_exclude_constraint :prices, :test_constraint'
          end

          let(:expected_irreversible_migration_error_message) do
            'To make this migration reversible, pass the constraint to '\
              'remove_exclude_constraint, i.e. `remove_exclude_constraint, '\
              ":prices, :test_constraint, 'price > 999'`"
          end

          it 'removes the exclude_constraint from the schema file' do
            schema = File.read(schema_file)
            expect(schema).not_to match(/exclude_constraint/)
          end

          it 'enforces the constraint' do
            Price.create! price: 999, from: 1.day.ago, to: 2.days.from_now
            expect { Price.create! price: 999, from: 2.days.ago, to: 1.day.from_now }.not_to(
              raise_error
            )

            # Ensure that we can safely roll back the migration that removed the
            # exclude constraint
            Price.destroy_all
          end

          def rollback
            expect { super }.to raise_error StandardError,
              /#{expected_irreversible_migration_error_message}/m
          end
        end
      end
    end
  end
end
