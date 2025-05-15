# Security Guide for dotnew-insights-engine

This document outlines the security measures implemented in the dotnew-insights-engine application.

## Transport Layer Security (TLS)

- Forced SSL in production environment
- HSTS (HTTP Strict Transport Security) enabled with:
  - Subdomains included
  - Preload enabled
  - 1-year expiration
- SSL termination configured for reverse proxy setup

```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = {
  hsts: { subdomains: true, preload: true, expires: 1.year }
}
```

## Cross-Origin Resource Sharing (CORS)

Strict CORS configuration with:
- Explicit allowed origins
- Credentials support
- Exposed headers for authentication
- Controlled HTTP methods

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://your-frontend-domain.com', 'https://www.your-frontend-domain.com'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end
```

## Rate Limiting and Request Filtering

Using `rack-attack` for request throttling and blocking:

```ruby
# config/initializers/rack_attack.rb
- Global rate limit: 300 requests per 5 minutes per IP
- Analytics endpoint limit: 60 requests per minute per IP
- Fail2Ban implementation for suspicious requests
- Automatic blocking of common attack patterns
```

## Security Headers

Comprehensive security headers implemented:

```ruby
- X-Frame-Options: SAMEORIGIN
- X-XSS-Protection: 1; mode=block
- X-Content-Type-Options: nosniff
- X-Download-Options: noopen
- X-Permitted-Cross-Domain-Policies: none
- Referrer-Policy: strict-origin-when-cross-origin
- Content-Security-Policy: default-src 'self'; frame-ancestors 'none'
- Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Database Security

- SSL enforced for database connections in production
- Credentials managed via environment variables
- SSL certificate verification enabled
- Connection pooling configured

```yaml
# Production database configuration includes:
- SSL mode: verify-full
- SSL certificate verification
- Separate credentials for different database roles
- Environment variable based configuration
```

## Input Validation and Sanitization

Model-level validations:
```ruby
# app/models/visitor.rb
- UUID presence and uniqueness validation
- IP address format validation
- User agent length restrictions
- Input sanitization before validation
```

## Parameter Filtering

Sensitive parameters filtered from logs:
```ruby
- Passwords and confirmations
- Tokens (API, Bearer, JWT, etc.)
- Credit card information
- Authentication credentials
- Email addresses
- Private keys and certificates
```

## Error Handling

Secure error handling implementation:
- Generic error messages in production
- Detailed logging for debugging
- Custom error pages for common HTTP status codes
- Prevention of information leakage in error responses

## Authentication & Authorization

Using Devise and Devise-JWT for authentication:
- JWT-based authentication
- Secure token management
- Session-less authentication for API
- Pundit for authorization policies

## Monitoring and Logging

Production monitoring setup:
- Sentry for error tracking
- Paper Trail for audit logging
- Rate limit monitoring
- Security event logging

## Additional Security Measures

1. Route Constraints
   - JSON format enforcement
   - Versioned API endpoints
   - Resource limitations

2. Development Security Tools
   - Brakeman for static code analysis
   - Bundle audit for dependency checking
   - RuboCop for code style enforcement

## Security Best Practices

1. Environment Variables
   - All sensitive configuration managed via environment variables
   - No hardcoded credentials
   - Secure credential management in production

2. Regular Updates
   - Dependency updates
   - Security patch application
   - Regular security audits

3. Production Configurations
   - Debug mode disabled
   - Proper logging levels
   - Error detail restrictions

## Deployment Security

Using Kamal for secure deployments:
- Docker container deployment
- Environment isolation
- Secure credential management
- SSL termination support

## Security Maintenance

Regular security tasks:
```bash
# Update dependencies
bundle update --conservative

# Run security audits
bundle audit check --update
brakeman --no-pager

# Check for outdated gems
bundle outdated
```

## Reporting Security Issues

If you discover a security issue, please report it by:
1. DO NOT create a public GitHub issue
2. Follow responsible disclosure practices
3. Contact the security team directly

## Additional Resources

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Rails Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Ruby_on_Rails_Cheat_Sheet.html)
- [Devise Documentation](https://github.com/heartcombo/devise)
- [Pundit Documentation](https://github.com/varvet/pundit) 