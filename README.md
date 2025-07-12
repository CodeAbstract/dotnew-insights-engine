# DotNew Insights Engine

A custom analytics API built with Rails 8 that provides detailed website traffic analysis, visitor tracking, and statistical reporting. The engine uses anonymous visitor tracking with UUID-based identification, making it easy to integrate with any frontend application without requiring user authentication.

## Core Features

1. **Visit Tracking**
   - Records visitor information with unique identifiers
   - Tracks session data including entry/exit times
   - Calculates bounce rates automatically

2. **Traffic Source Analysis**
   - Identifies traffic sources (direct, search, referral, social)
   - Detects device types (desktop, mobile, tablet)
   - Records geographical data (country, region, city)

3. **Page Analytics**
   - Tracks page views with timestamps
   - Associates views with specific visits and visitors
   - Provides path-based analytics

4. **Statistical Reporting**
   - Offers flexible timeframe reporting (day, week, month, year)
   - Calculates key metrics like bounce rate and visit duration
   - Provides aggregated data by various dimensions

## Requirements

### Ruby version
- Ruby 3.2.5 or higher
- Rails 8.0.2

### System dependencies
- PostgreSQL 14+ (for database)
- Node.js 18+ (for JavaScript runtime)
- Redis (optional, for caching)
- MaxMind GeoIP2 database (for IP geolocation)

### Gem Dependencies
```ruby
# Core gems
gem 'rails', '~> 8.0.2'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rack-cors'
gem 'geoip2'

# Security
gem 'rack-attack'
gem 'rack-attack-rate-limit'

# Performance & Caching
gem 'solid_cache'
gem 'solid_queue'
gem 'solid_cable'
```

## Frontend Integration Guides

### Common Setup

First, create a configuration file for your analytics endpoints:

```javascript
// src/config/analytics.js (or .ts)
const config = {
  development: {
    apiBaseUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1',
  },
  production: {
    apiBaseUrl: process.env.REACT_APP_API_URL || 'https://your-api-domain.com/api/v1',
  },
};

export default config[process.env.NODE_ENV || 'development'];
```

### React with TypeScript

Create the analytics hook:

```typescript
// src/hooks/useAnalytics.ts
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import config from '../config/analytics';

interface VisitData {
  visitor_uuid?: string;
  visit_id?: number;
}

export const useAnalytics = () => {
  const location = useLocation();

  const trackPageView = async (path: string): Promise<VisitData> => {
    try {
      const visitorUuid = localStorage.getItem('visitor_uuid');
      const data = {
        page_path: path,
        visitor_uuid: visitorUuid,
      };

      const response = await fetch(`${config.apiBaseUrl}/analytics/track`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      const result = await response.json();
      if (result.visitor_uuid) {
        localStorage.setItem('visitor_uuid', result.visitor_uuid);
      }
      if (result.visit_id) {
        sessionStorage.setItem('visit_id', result.visit_id.toString());
      }

      return result;
    } catch (error) {
      console.error('Analytics tracking error:', error);
      return {};
    }
  };

  useEffect(() => {
    trackPageView(location.pathname);
  }, [location.pathname]);

  return { trackPageView };
};
```

Usage in components:

```typescript
// src/App.tsx
import { useAnalytics } from './hooks/useAnalytics';

const App: React.FC = () => {
  useAnalytics(); // This will automatically track page views
  return <div>{/* Your app content */}</div>;
};
```

### React with JavaScript

The implementation is similar to TypeScript but without type definitions:

```javascript
// src/hooks/useAnalytics.js
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import config from '../config/analytics';

export const useAnalytics = () => {
  const location = useLocation();

  const trackPageView = async (path) => {
    try {
      const visitorUuid = localStorage.getItem('visitor_uuid');
      const data = {
        page_path: path,
        visitor_uuid: visitorUuid,
      };

      const response = await fetch(`${config.apiBaseUrl}/analytics/track`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      const result = await response.json();
      if (result.visitor_uuid) {
        localStorage.setItem('visitor_uuid', result.visitor_uuid);
      }
      if (result.visit_id) {
        sessionStorage.setItem('visit_id', result.visit_id.toString());
      }

      return result;
    } catch (error) {
      console.error('Analytics tracking error:', error);
      return {};
    }
  };

  useEffect(() => {
    trackPageView(location.pathname);
  }, [location.pathname]);

  return { trackPageView };
};
```

### Next.js Integration

For Next.js applications, create the analytics component:

```typescript
// src/components/Analytics.tsx (or .jsx)
'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import config from '@/config/analytics';

export function Analytics() {
  const pathname = usePathname();

  const trackPageView = async (path: string) => {
    try {
      const visitorUuid = localStorage.getItem('visitor_uuid');
      const data = {
        page_path: path,
        visitor_uuid: visitorUuid,
      };

      const response = await fetch(`${config.apiBaseUrl}/analytics/track`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      const result = await response.json();
      if (result.visitor_uuid) {
        localStorage.setItem('visitor_uuid', result.visitor_uuid);
      }
      if (result.visit_id) {
        sessionStorage.setItem('visit_id', result.visit_id.toString());
      }
    } catch (error) {
      console.error('Analytics tracking error:', error);
    }
  };

  useEffect(() => {
    if (typeof window !== 'undefined') {
      trackPageView(pathname);
    }
  }, [pathname]);

  return null;
}
```

Add to your app layout:

```typescript
// src/app/layout.tsx (or .jsx)
import { Analytics } from '@/components/Analytics';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Analytics />
        {children}
      </body>
    </html>
  );
}
```

### Environment Setup

For all frontend applications, set up your environment variables:

```bash
# .env.development
REACT_APP_API_URL=http://localhost:3000/api/v1
# or for Next.js
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1

# .env.production
REACT_APP_API_URL=https://your-api-domain.com/api/v1
# or for Next.js
NEXT_PUBLIC_API_URL=https://your-api-domain.com/api/v1
```

## Backend Configuration

### Initial Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/dotnew-insights-engine.git
cd dotnew-insights-engine

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Start the server
rails server
```

### Environment Variables
Create a `.env` file in the root directory with the following variables:
```bash
# Database Configuration
DB_NAME=your_database_name
DB_USERNAME=your_database_user
DB_PASSWORD=your_database_password
DB_HOST=your_database_host
DB_PORT=5432

# SSL Configuration (Production)
DB_SSLMODE=verify-full
DB_SSLCERT=path/to/cert
DB_SSLKEY=path/to/key
DB_SSLROOTCERT=path/to/rootcert

# API Configuration
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.your-frontend-domain.com

# Security
RAILS_MASTER_KEY=your_master_key
SECRET_KEY_BASE=your_secret_key_base


```

## API Documentation

### Track Page View
`POST /api/v1/analytics/track`

```json
{
  "visitor_uuid": "optional-existing-visitor-id",
  "page_path": "/current/page/path"
}
```

### End Visit
`POST /api/v1/analytics/end_visit`

```json
{
  "visit_id": 123
}
```

### Get Analytics Stats
`GET /api/v1/analytics/stats?timeframe=day`

## Security

### Transport Layer Security (TLS)
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

### Cross-Origin Resource Sharing (CORS)
Strict CORS configuration with:
- Explicit allowed origins (environment-specific)
- Credentials support
- Controlled HTTP methods
- Development-specific settings for local testing

```ruby
# config/initializers/cors.rb
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
      credentials: true
  end
end
```

### Rate Limiting and Request Filtering
Using `rack-attack` for request throttling and blocking:

```ruby
# config/initializers/rack_attack.rb
# Global rate limit
throttle('req/ip', limit: ENV.fetch('GLOBAL_RATE_LIMIT', 300).to_i, period: ENV.fetch('GLOBAL_RATE_LIMIT_PERIOD', 300).to_i)

# Analytics endpoint specific limit
throttle('analytics/track/ip', limit: ENV.fetch('TRACK_RATE_LIMIT', 60).to_i, period: ENV.fetch('TRACK_RATE_LIMIT_PERIOD', 60).to_i)

# API rate limit
throttle('api/ip', limit: ENV.fetch('API_RATE_LIMIT_MAX_REQUESTS', 100).to_i, period: ENV.fetch('API_RATE_LIMIT_WINDOW', 300).to_i)

# Block suspicious requests (Fail2Ban)
blocklist('block suspicious requests') do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour)
end
```

### Security Headers
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

### Database Security
- SSL enforced for database connections in production
- Credentials managed via environment variables
- Connection pooling configured via `RAILS_MAX_THREADS`

### Input Validation and Sanitization
Model-level validations:
```ruby
# app/models/visitor.rb
validates :uuid, presence: true, uniqueness: true
validates :ip_address, presence: true
validates :user_agent, presence: true, length: { maximum: 500 }

# Input sanitization
before_validation :sanitize_inputs
```

### Parameter Filtering
Sensitive parameters filtered from logs:
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :credit_card, :card_number, :auth, :api_key, :access_token, :bearer_token,
  :jwt, :refresh_token, :cookie, :session, :password_confirmation, :secret_key,
  :private_key, :email
]
```

### Error Handling
Secure error handling implementation:
```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      handle_error(e)
    end

    private

    def handle_error(error)
      case error
      when ActiveRecord::RecordNotFound
        render_error(:not_found, error.message)
      when ActiveRecord::RecordInvalid
        render_error(:unprocessable_entity, error.record.errors.full_messages)
      else
        Rails.logger.error("Unexpected error: #{error.class} - #{error.message}")
        render_error(:internal_server_error, 'An unexpected error occurred')
      end
    end
  end
end
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Support

For support, please:
1. Check the [documentation](docs/)
2. Search [existing issues](issues/)
3. Create a new issue if needed

## Authors

- New Aguda - (https://github.com/codeabstract)


## Best Practices Implemented

### Service Objects Pattern
The application follows the Service Objects pattern to encapsulate business logic:

- `Analytics::VisitTrackerService`: Manages visit tracking and page view recording
- `Analytics::GeoLocationService`: Handles IP-based geolocation
- `Analytics::DeviceDetectorService`: Detects user device types
- `Analytics::SourceDetectorService`: Identifies traffic sources
- `Analytics::StatsService`: Generates analytics reports and statistics

### Separation of Concerns
- Controllers handle HTTP requests and responses
- Service objects contain business logic
- Models handle data persistence and validations
- Concerns manage shared functionality

### DRY (Don't Repeat Yourself)
- Shared error handling via `ErrorHandler` concern
- Reusable service objects for common operations
- Model scopes for frequent queries
- Centralized validation logic

### API Best Practices
1. **Versioning**
   ```
   /api/v1/analytics/track
   /api/v1/analytics/stats
   ```

2. **Error Handling**
   ```json
   {
     "error": {
       "status": "not_found",
       "message": "Resource not found"
     }
   }
   ```

3. **Parameter Validation**
   - Strong parameters
   - Required field validation
   - Type checking

4. **Response Consistency**
   - Standard JSON format
   - Proper HTTP status codes
   - Consistent error structure

### Security Measures
- Rate limiting and request throttling
- Error message sanitization
- Proper error logging
- IP address validation
- User agent sanitization
- CORS protection
- SSL/TLS in production
- Parameter filtering
- Input validation

### Performance Optimizations
- Counter cache for page views
- Database query optimization
- Efficient scopes
- Caching of expensive operations

### Code Organization
```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       └── analytics_controller.rb
│   └── concerns/
│       └── error_handler.rb
├── models/
│   ├── visitor.rb
│   ├── visit.rb
│   └── page_view.rb
└── services/
    └── analytics/
        ├── visit_tracker_service.rb
        ├── geo_location_service.rb
        ├── device_detector_service.rb
        ├── source_detector_service.rb
        └── stats_service.rb
```

### Testing (Recommended)
- Unit tests for models and services
- Integration tests for API endpoints
- Test coverage for error scenarios
- Performance testing for analytics

### Documentation
- API documentation
- Code documentation
- Implementation guides
- Security guidelines

## Testing Suite

The application includes a comprehensive testing suite using RSpec. The tests cover models, services, and controllers, ensuring the reliability and correctness of the analytics engine.

### Test Structure

```
spec/
├── models/
│   ├── visitor_spec.rb
│   ├── visit_spec.rb
│   └── page_view_spec.rb
├── services/
│   └── analytics/
│       ├── visit_tracker_service_spec.rb
│       ├── geo_location_service_spec.rb
│       ├── device_detector_service_spec.rb
│       ├── source_detector_service_spec.rb
│       └── stats_service_spec.rb
├── controllers/
│   └── api/
│       └── v1/
│           └── analytics_controller_spec.rb
└── factories/
    ├── visitors.rb
    ├── visits.rb
    └── page_views.rb
```

### Test Coverage

- **Model Tests**: Validate associations, validations, scopes, and instance methods
- **Service Tests**: Ensure business logic works correctly
- **Controller Tests**: Verify API endpoints and error handling
- **Factory Definitions**: Provide test data generators

### Running Tests

```bash
# Install test dependencies
bundle install

# Run the entire test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/visitor_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run tests in parallel
bundle exec parallel_rspec spec/
```

### Test Tools and Libraries

- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **Faker**: Generate realistic test data
- **Shoulda Matchers**: Simplified testing of Rails functionality
- **DatabaseCleaner**: Ensure clean state between tests
- **SimpleCov**: Test coverage reporting
- **VCR**: Record and replay HTTP interactions
- **WebMock**: Mock HTTP requests
- **Timecop**: Time manipulation in tests

### Continuous Integration

The test suite is integrated with CI/CD pipelines and runs:
- On every pull request
- Before deployment to staging
- Before deployment to production

### Code Coverage Requirements

- Minimum coverage threshold: 95%
- Critical paths require 100% coverage:
  - Visit tracking
  - Analytics calculations
  - API endpoints
  - Error handling

## Environment Variables

The application uses environment variables for configuration. Create a `.env` file in the root directory with the following variables:

### Required Variables (Production)

```
# Database Configuration
DATABASE_URL=postgresql://user:password@host:port/database_name
TEST_DATABASE_URL=postgresql://user:password@host:port/test_database_name

# Security
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here

# GeoIP Configuration
GEOIP_LICENSE_KEY=your_geoip_license_key_here
GEOIP_ACCOUNT_ID=your_geoip_account_id_here

# CORS Configuration
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.your-frontend-domain.com
```

### Optional Variables (with defaults)

```
# Rails Configuration
RAILS_ENV=development
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
PORT=3000

# Rate Limiting
GLOBAL_RATE_LIMIT=300
GLOBAL_RATE_LIMIT_PERIOD=300 # 5 minutes in seconds
TRACK_RATE_LIMIT=60
TRACK_RATE_LIMIT_PERIOD=60 # 1 minute in seconds
API_RATE_LIMIT_MAX_REQUESTS=100
API_RATE_LIMIT_WINDOW=300 # 5 minutes in seconds
```

### Setting Up Environment Variables

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your specific values:
   ```bash
   vim .env
   ```

3. For production, ensure all required variables are set in your deployment environment.
