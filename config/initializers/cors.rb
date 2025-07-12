# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # In development, allow localhost origins
      origins 'localhost:3000', '127.0.0.1:3000', 'localhost:5173', '127.0.0.1:5173',
              'localhost:8080', '127.0.0.1:8080'
    else
      # In production, only allow specific domains
      origins ENV.fetch('ALLOWED_ORIGINS', '').split(',')
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end

  # For development assets (if needed)
  if Rails.env.development?
    allow do
      origins '*'
      resource '/assets/*',
        headers: :any,
        methods: [:get, :options],
        credentials: false
    end
  end
end
