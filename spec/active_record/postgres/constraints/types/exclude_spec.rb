# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveRecord::Postgres::Constraints::Types::Exclude, :constraint do
  context 'when a migration adds an exclude constraint' do
    shared_examples_for 'adds a constraint' do
      let(:expected_schema) do
        <<-MIGRATION

          #{create_table_line_of_schema_file(:phases)}
            t\.integer {1,2}"project_id"
            t\.datetime "from"
            t\.datetime "to"
            t\.exclude_constraint :test_constraint, #{expected_constraint_string}
          end
        MIGRATION
      end

      it { should include_the_constraint_in_the_schema_file }

      it 'enforces the constraint for a different project only if there is no WHERE clause' do
        create_phase(1.day.ago, 1.day.from_now)
        create_phase(2.days.from_now, nil)
        create_excluded_phase_with_project_id_of_1
        expect { create_excluded_phase_with_project_id_of_1 }.
          public_send(*(where_clause ? [:not_to, raise_error] : [:to, raise_statement_invalid]))
      end

      it 'enforces the constraint for the same project and an overlapping time range' do
        create_phase(1.day.ago, 1.day.from_now)
        expect { create_phase(Time.current, 2.days.from_now) }.to(raise_statement_invalid)
      end
    end

    def create_phase(from, to, project_id = 999)
      Phase.create!(project_id: project_id, from: from, to: to)
    end

    def create_excluded_phase_with_project_id_of_1
      create_phase(Time.current, 2.days.from_now, 1)
    end

    def raise_statement_invalid
      raise_error(ActiveRecord::StatementInvalid, expected_error_regex)
    end

    let(:model_class) { 'Phase' }

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

      let(:expected_constraint_string) do
        'using: :gist, \'tsrange\("from", "to"\)\' => :overlaps, project_id: :equals'
      end

      context 'when the constraint is a String' do
        let(:constraint) do
          'using: :gist, \'tsrange("from", "to")\' => :overlaps, :project_id => :equals'
        end

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) { "#{super()}, where: 'project_id <> 1'" }
          let(:expected_constraint_string) { "#{super()}, where: '\\(project_id <> 1\\)'" }

          it_behaves_like 'adds a constraint'
        end

        context 'when the migration contains additional indexes' do
          let(:content_of_change_method) do
            <<-MIGRATION
              enable_extension "btree_gist"
              #{create_table_line_of_schema_file(:phases)}
                t.integer  :project_id
                t.datetime :from
                t.datetime :to
                t.index [:project_id, :from]
                t.exclude_constraint :test_constraint, #{constraint}
              end
            MIGRATION
          end

          it_behaves_like 'adds a constraint' do
            let(:expected_schema) do
              <<-MIGRATION

                #{create_table_line_of_schema_file(:phases)}
                  t\.integer {1,2}"project_id"
                  t\.datetime "from"
                  t\.datetime "to"
                  t\.index \\["project_id", "from"\\], name: "index_phases_on_project_id_and_from"#{', using: :btree' unless rails_gte_5_1_0?}
                  t\.exclude_constraint :test_constraint, #{expected_constraint_string}
                end
              MIGRATION
            end
          end
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
            let(:expected_schema) do
              <<-MIGRATION

                #{create_table_line_of_schema_file(:phases)}
                  t\.integer {1,2}"project_id"
                  t\.datetime "from"
                  t\.datetime "to"
                  t\.exclude_constraint :phases_[0-9]{7,9}, #{expected_constraint_string}
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

        it_behaves_like 'adds a constraint'

        context 'when a where clause is present' do
          let(:where_clause) { true }
          let(:constraint) { super().merge(where: 'project_id <> 1') }
          let(:expected_constraint_string) { "#{super()}, where: '\\(project_id <> 1\\)'" }

          it_behaves_like 'adds a constraint'
        end
      end
    end

    context 'when using add_exclude_constraint' do
      let(:constraint) do
        { using: :gist, 'tsrange("from", "to")' => :overlaps, project_id: :equals }
      end
      let(:expected_constraint_string) do
        'using: :gist, \'tsrange\("from", "to"\)\' => :overlaps, project_id: :equals'
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
          'using: :gist, \'tsrange("from", "to")\' =>  :overlaps, '\
          ':project_id => :equals, where: \'project_id <> 1\''
        end
        let(:expected_constraint_string) do
          "#{super()}, where: '\\(project_id <> 1\\)'"
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

        def create_overlapping_phase
          create_phase(Time.current, 2.days.from_now)
          create_phase(1.day.ago, 1.day.from_now)
        end

        it 'does not enforce the constraint until we rollback the second migration' do
          expect { create_overlapping_phase }.not_to(raise_error)

          # Ensure that we can safely roll back the migration that removed the exclude constraint
          Phase.destroy_all
          rollback

          expect { create_overlapping_phase }.to(raise_statement_invalid)
        end

        context 'when remove_exclude_constraint is irreversible' do
          let(:content_of_change_method_for_removing_migration) do
            'remove_exclude_constraint :phases, :test_constraint'
          end

          let(:expected_irreversible_migration_error_message) do
            'To make this migration reversible, pass the constraint to '\
              'remove_exclude_constraint, i\.e\. `remove_exclude_constraint '\
              ':phases, :test_constraint, using: :gist, \'tsrange\("from", "to"\)\''\
              ' => :overlaps, project_id: :equals`'
          end

          it 'removes the exclude_constraint from the schema file' do
            schema = File.read(schema_file)
            expect(schema).not_to match(/exclude_constraint/)
          end

          it 'does not enforce the constraint' do
            create_phase(1.day.ago, 2.days.from_now)
            expect { create_phase(2.days.ago, 1.day.from_now) }.not_to(raise_error)

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
