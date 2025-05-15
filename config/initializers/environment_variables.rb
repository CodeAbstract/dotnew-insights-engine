module EnvironmentVariables
  REQUIRED_VARIABLES = {
    'DATABASE_URL' => 'Database connection URL',
    'RAILS_MASTER_KEY' => 'Rails master key for credentials',
    'SECRET_KEY_BASE' => 'Secret key base for Rails',
    'GEOIP_LICENSE_KEY' => 'GeoIP service license key',
    'GEOIP_ACCOUNT_ID' => 'GeoIP service account ID'
  }

  def self.validate_presence!
    missing_vars = REQUIRED_VARIABLES.select { |var, _| ENV[var].blank? }
    
    return if missing_vars.empty?

    error_message = missing_vars.map { |var, desc| "#{var} (#{desc})" }.join(', ')
    raise "Missing required environment variables: #{error_message}"
  end
end

# Only validate in production to allow development without all variables
if Rails.env.production?
  EnvironmentVariables.validate_presence!
end 