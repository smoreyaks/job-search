# Be sure to restart your server when you modify this file.
#
# Allow the Angular dev app to call this API cross-origin. Override the origin
# with the ANGULAR_ORIGIN env var in other environments.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("ANGULAR_ORIGIN", "http://localhost:4200")

    resource "*",
             headers: :any,
             methods: %i[get post patch put delete options head]
  end
end
