# frozen_string_literal: true

module ActiveRecord
  module Postgres
    module Constraints
      class Railtie < Rails::Railtie
        initializer 'active_record.postgres.constraints.patch_active_record' do |*_args|
          engine = self
          ActiveSupport.on_load(:active_record) do
            AR_CAS = ::ActiveRecord::ConnectionAdapters

            engine.apply_patch! if engine.pg?
          end
        end

        def apply_patch!
          Rails.logger.info do
            'Applying Postgres Constraints patches to ActiveRecord'
          end
          AR_CAS::TableDefinition.include TableDefinition
          AR_CAS::PostgreSQLAdapter.include PostgreSQLAdapter
          AR_CAS::AbstractAdapter::SchemaCreation.prepend SchemaCreation

          ::ActiveRecord::Migration::CommandRecorder.include CommandRecorder
          ::ActiveRecord::SchemaDumper.prepend SchemaDumper
        end

        def pg?
          begin
            connection = ActiveRecord::Base.connection
          rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
            Rails.logger.warn do
              'Not applying Postgres Constraints patches to ActiveRecord ' \
                'since the database does not exist'
            end
            return false
          end

          pg = connection.class.to_s == "#{AR_CAS}::PostgreSQLAdapter"
          return true if pg

          Rails.logger.warn do
            'Not applying Postgres Constraints patches to ActiveRecord ' \
              'since the database is not postgres'
          end
          false
        end
      end
    end
  end
end
