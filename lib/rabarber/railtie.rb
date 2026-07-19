# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    def self.server_running?
      !!defined?(Rails::Server)
    end

    def self.table_exists?
      ActiveRecord::Base.connection.data_source_exists?("rabarber_roles")
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
      false
    end

    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        if Rabarber::Railtie.server_running? && Rabarber::Railtie.table_exists?
          Rabarber::Role.where.not(context_type: nil).distinct.pluck(:context_type).each do |context_class|
            context_class.constantize
          rescue NameError => e
            raise Rabarber::Error, "Context not found: class `#{e.name}` may have been renamed or deleted"
          end
        end

        Rabarber::Core::Permissions.reset! unless app.config.eager_load

        begin
          user_model = Rabarber::Configuration.user_model
          user_model.include Rabarber::Roleable unless user_model < Rabarber::Roleable
        rescue Rabarber::ConfigurationError
          raise if Rabarber::Railtie.server_running?
        end

        Rabarber::Role.send(:remove_const, :HABTM_Roleables) if Rabarber::Role.const_defined?(:HABTM_Roleables, false)
        Rabarber::Role.has_and_belongs_to_many :roleables, class_name: Rabarber::Configuration.user_model_name,
                                                           association_foreign_key: "roleable_id",
                                                           join_table: "rabarber_roles_roleables"
      end
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
