# DotNew Insights Engine

A custom analytics API built with Rails 8 that provides detailed website traffic analysis, visitor tracking, and statistical reporting.

## Core Features

1. **Visit Tracking**
   - Records visitor information with unique UUIDs
   - Tracks session data with entry/exit times
   - Calculates bounce rates based on page view count
   - Tracks visit duration automatically

2. **Traffic Analysis**
   - Detects traffic sources (direct, search, referral, social)
   - Identifies device types (desktop, mobile, tablet)
   - Records geographical data via MaxMind GeoIP2 (country, region, city)
   - Handles local and private IP addresses

3. **Page Analytics**
   - Tracks page views with timestamps
   - Associates views with visits and visitors
   - Maintains page view counts per visit
   - Provides path-based analytics

4. **Statistical Reporting**
   - Offers flexible timeframes (day, week, month, year)
   - Provides summary statistics:
     - Total visits and unique visitors
     - Page view counts
     - Bounce rates
     - Average visit duration
   - Groups data by:
     - Traffic sources
     - Device types
     - Geographic locations
     - Page paths

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
config.assume_ssl = true
config.force_ssl = true
config.ssl_options = {
  hsts: { subdomains: true, preload: true, expires: 1.year }
}
```

### Cross-Origin Resource Sharing (CORS)
Strict CORS configuration with:
- Environment-specific origins:
  - Development: localhost:3000, localhost:5173, localhost:8080
  - Production: Configurable via ALLOWED_ORIGINS
- Credentials support enabled
- Controlled HTTP methods
- Special handling for development assets

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      origins 'localhost:3000', '127.0.0.1:3000', 'localhost:5173', 
              'localhost:8080'
    else
      origins ENV.fetch('ALLOWED_ORIGINS', '').split(',')
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end
```

### Rate Limiting and Request Filtering
Using `rack-attack` for request throttling and blocking:

```ruby
# config/initializers/rack_attack.rb
# Global rate limit
throttle('req/ip', limit: ENV.fetch('GLOBAL_RATE_LIMIT', 300).to_i, 
         period: ENV.fetch('GLOBAL_RATE_LIMIT_PERIOD', 300).to_i)

# Analytics endpoint specific limit
throttle('analytics/track/ip', limit: ENV.fetch('TRACK_RATE_LIMIT', 60).to_i,
         period: ENV.fetch('TRACK_RATE_LIMIT_PERIOD', 60).to_i)

# Block suspicious requests
blocklist('block suspicious requests') do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}",
    maxretry: 3, findtime: 10.minutes, bantime: 1.hour)
end
```


### Environment Variables Validation
Required environment variables are validated in production:
```ruby
# config/initializers/environment_variables.rb
REQUIRED_VARIABLES = {
  'DATABASE_URL' => 'Database connection URL',
  'RAILS_MASTER_KEY' => 'Rails master key for credentials',
  'SECRET_KEY_BASE' => 'Secret key base for Rails',
  'GEOIP_LICENSE_KEY' => 'GeoIP service license key',
  'GEOIP_ACCOUNT_ID' => 'GeoIP service account ID'
}
```

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

### Testing

The application includes a comprehensive testing suite using RSpec. The tests cover models, services, and controllers, ensuring the reliability and correctness of the analytics engine.

### Test Coverage

The application has a comprehensive test suite with RSpec, achieving an overall line coverage of **94.35%** (284/301 lines).

### Running Tests with Coverage

```bash
# Run tests with coverage report
COVERAGE=true bundle exec rspec

# View detailed coverage report
open coverage/index.html
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


## Author/s

- Code Abstract - (https://github.com/codeabstract)