# frozen_string_literal: true

require 'rails_helper'
require 'shared_migration_methods'

RSpec.describe ActiveRecord::Postgres::Constraints::Types::Exclude do
  context 'when a migration adds an exclude constraint' do
    include SharedMigrationMethods

    class ApplicationRecord < ActiveRecord::Base; self.abstract_class = true; end
    class Phase < ApplicationRecord; end

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
          create_table "phases", #{'id: :serial, ' if Gem::Version.new(ActiveRecord.gem_version) >= Gem::Version.new('5.1.0')}force: :cascade do |t|
            t.integer #{' ' if Gem::Version.new(ActiveRecord.gem_version) < Gem::Version.new('5.1.0')}"project_id"
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
        create_phase = ->(from, to, project_id = 999) {
          Phase.create! project_id: project_id, from: from, to: to
        }

        create_phase.call(1.day.ago, 1.day.from_now)
        expect { create_phase.call(Time.current, 2.days.from_now) }.to(
          raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
        )
        create_phase.call(2.days.from_now, nil)
        create_phase.call(Time.current, 2.days.from_now, 1)
        if where_clause
          create_phase.call(Time.current, 2.days.from_now, 1)
        else
          expect { create_phase.call(Time.current, 2.days.from_now, 1) }.to(
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
          create_table :phases do |t|
            t.integer  :project_id
            t.datetime :from
            t.datetime :to
            t.exclude_constraint :test_constraint, #{constraint}
          end
        MIGRATION
      end

      context 'when the constraint is a String' do
        let(:constraint) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          ':project_id => :equals'
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          'project_id: :equals'
        end

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            ':project_id => :equals, where: \'project_id <> 1\''
          end
          let(:expected_constraint_string) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'project_id: :equals, where: \'(project_id <> 1)\''
          end

          it_behaves_like 'adds a constraint'
        end

        context 'when the constraint is anonymous' do
          let(:content_of_change_method) do
            <<-MIGRATION
              enable_extension "btree_gist"
              create_table :phases do |t|
                t.integer  :project_id
                t.datetime :from
                t.datetime :to
                t.exclude_constraint   #{constraint}
              end
            MIGRATION
          end

          let(:expected_constraint_error_message) do
            'PG::ExclusionViolation: ERROR:  conflicting key value violates '\
            'exclusion constraint "phases_[0-9]{7,9}"'
          end

          it_behaves_like 'adds a constraint' do
            let(:expected_schema_regex) do
              Regexp.new <<-MIGRATION.strip_heredoc.indent(2)
                create_table "phases", force: :cascade do \|t\|
                  t.integer  #{' ' if Gem::Version.new(ActiveRecord.gem_version) < Gem::Version.new('5.1.0')}"project_id"
                  t.datetime "from"
                  t.datetime "to"
                  t.exclude_constraint :phases_[0-9]{7,9}, #{expected_constraint_string}
                end
              MIGRATION
            end
          end
        end
      end

      context 'when the constraint is a Hash' do
        let(:constraint) do
          { using: :gist, 'tsrange("from", "to")' => :overlaps, project_id: :equals }
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
          'project_id: :equals'
        end

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) do
            {
              using: :gist,
              'tsrange("from", "to")' => :overlaps,
              project_id: :equals,
              where: 'project_id <> 1',
            }
          end
          let(:expected_constraint_string) do
            'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'project_id: :equals, where: \'(project_id <> 1)\''
          end

          it_behaves_like 'adds a constraint'
        end
      end
    end

    context 'when using add_exclude_constraint' do
      let(:constraint) do
        { using: :gist, 'tsrange("from", "to")' => :overlaps, project_id: :equals }
      end
      let(:expected_constraint_string) do
        'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
        'project_id: :equals'
      end
      let(:content_of_change_method) do
        <<-MIGRATION
          enable_extension "btree_gist"
          create_table :phases do |t|
            t.integer  :project_id
            t.datetime :from
            t.datetime :to
          end
          add_exclude_constraint :phases, :test_constraint, #{constraint}
        MIGRATION
      end

      it_behaves_like 'adds a constraint'

      context 'when a where clause is present' do
        let(:where_clause) { true }
        let(:constraint) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            ':project_id => :equals, where: \'project_id <> 1\''
        end
        let(:expected_constraint_string) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, '\
            'project_id: :equals, where: \'(project_id <> 1)\''
        end

        it_behaves_like 'adds a constraint'
      end

      context 'when the constraint is removed in a later migration' do
        let(:content_of_change_method_for_removing_migration) do
          "remove_exclude_constraint :phases, :test_constraint, #{constraint}"
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
          create_phase = ->(from, to) { Phase.create! project_id: 999, from: from, to: to }

          create_phase.call(Time.current, 2.days.from_now)
          expect { create_phase.call(1.day.ago, 1.day.from_now) }.not_to(raise_error)

          # Ensure that we can safely roll back the migration that removed the
          # exclude constraint
          Phase.destroy_all

          rollback

          create_phase.call(Time.current, 2.days.from_now)
          expect { create_phase.call(1.day.ago, 1.day.from_now) }.to(
            raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
          )
        end

        context 'when remove_exclude_constraint is irreversible' do
          let(:content_of_change_method_for_removing_migration) do
            'remove_exclude_constraint :phases, :test_constraint'
          end

          let(:expected_irreversible_migration_error_message) do
            'To make this migration reversible, pass the constraint to '\
              'remove_exclude_constraint, i.e. `remove_exclude_constraint, '\
              ":phases, :test_constraint, 'price > 999'`"
          end

          it 'removes the exclude_constraint from the schema file' do
            schema = File.read(schema_file)
            expect(schema).not_to match(/exclude_constraint/)
          end

          it 'enforces the constraint' do
            Phase.create! project_id: 999, from: 1.day.ago, to: 2.days.from_now
            expect { Phase.create! project_id: 999, from: 2.days.ago, to: 1.day.from_now }.not_to(
              raise_error
            )

            # Ensure that we can safely roll back the migration that removed the
            # exclude constraint
            Phase.destroy_all
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
