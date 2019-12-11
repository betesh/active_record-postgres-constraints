# frozen_string_literal: true

require_relative 'boot'

require 'active_model/railtie'
require 'active_record/railtie'

Bundler.require(*Rails.groups)
require 'active_record/postgres/constraints'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified
    # here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
