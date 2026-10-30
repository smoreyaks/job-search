require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JobSearchDashboard
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Zeitwerk autoload paths for hexagonal architecture
    # app/core is a root, so its subdirs become namespaces:
    #   app/core/domain/job_listing.rb   -> Domain::JobListing
    #   app/core/use_cases/search_jobs.rb -> UseCases::SearchJobs
    # Namespacing keeps domain entities from colliding with the ActiveRecord
    # models of the same name (JobListing, Resume, CoverLetter) in app/models.
    # Ports and adapters stay top-level.
    config.autoload_paths += %W[
      #{config.root}/app/core
      #{config.root}/app/ports
      #{config.root}/app/adapters/database
      #{config.root}/app/adapters/job_boards
      #{config.root}/app/adapters/ai
      #{config.root}/app/adapters/files
    ]

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
