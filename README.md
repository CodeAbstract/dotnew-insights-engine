# DotNew Insights Engine

A comprehensive analytics API built with Rails 8 that provides detailed website traffic analysis, visitor tracking, and statistical reporting.

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

# Authentication & Authorization
gem 'devise'
gem 'devise-jwt'
gem 'pundit'

# Security
gem 'rack-attack'
gem 'rack-attack-rate-limit'

# Monitoring & Logging
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'paper_trail'

# Performance & Caching
gem 'solid_cache'
gem 'solid_queue'
gem 'solid_cable'
```

## Configuration

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

# Monitoring
SENTRY_DSN=your_sentry_dsn
```

### Database Creation and Setup
```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Add indexes for analytics queries
rails db:migrate:analytics_indexes

# Seed initial data (if needed)
rails db:seed
```

## Testing

The project includes a comprehensive test suite with both unit tests and integration tests using RSpec.

### Test Structure

```bash
spec/
├── models/           # Unit tests for models
├── controllers/      # Integration tests for API endpoints
│   └── api/
│       └── v1/
├── factories/        # Factory definitions
├── support/         # Test helpers and shared examples
├── rails_helper.rb  # Rails-specific configuration
└── spec_helper.rb   # RSpec configuration
```

### Test Types

#### Unit Tests
Located in `spec/models/`, these tests verify individual components in isolation:
- Model validations
- Associations
- Instance methods
- Class methods
- Business logic

Example of a model test:
```ruby
RSpec.describe Visitor, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:uuid) }
    it { should validate_uniqueness_of(:uuid) }
  end

  describe 'associations' do
    it { should have_many(:visits) }
  end
end
```

#### Integration Tests
Located in `spec/controllers/api/v1/`, these tests verify:
- API endpoint functionality
- Request-response cycles
- Database interactions
- JSON response structures
- Error handling
- Edge cases

Example of an API controller test:
```ruby
RSpec.describe Api::V1::AnalyticsController, type: :controller do
  describe 'POST #track' do
    it 'creates a new visit' do
      post :track, params: { page_path: '/test' }
      expect(response).to have_http_status(:ok)
    end
  end
end
```

### Test Dependencies

The test suite uses several key testing gems:
- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **Shoulda Matchers**: Simplified testing syntax
- **Database Cleaner**: Test database management
- **SimpleCov**: Test coverage reporting
- **VCR**: HTTP interaction recording
- **WebMock**: HTTP request stubbing

### Running Tests

```bash
# Run the entire test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/visitor_spec.rb

# Run tests with coverage report
COVERAGE=true bundle exec rspec

# Run tests by type
bundle exec rspec spec/models/        # Run only unit tests
bundle exec rspec spec/controllers/   # Run only integration tests

# Run tests with specific tag
bundle exec rspec --tag focus

# Run tests with detailed output
bundle exec rspec --format documentation
```

### Test Coverage

To view test coverage:
1. Run tests with coverage enabled: `COVERAGE=true bundle exec rspec`
2. Open `coverage/index.html` in your browser
3. Review coverage metrics and identify areas needing additional testing

### Writing New Tests

When adding new features, follow these testing guidelines:
1. Write tests before implementing features (TDD)
2. Include both happy and sad path scenarios
3. Use meaningful context and description blocks
4. Follow the existing test patterns
5. Use factories instead of fixtures
6. Keep tests focused and isolated

### Continuous Integration

Tests are automatically run in the CI pipeline on:
- Pull requests
- Merges to main branch
- Release tags

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

## Client-Side Integration

### JavaScript Tracker
```javascript
// analytics.js
class Analytics {
  constructor() {
    this.visitorUuid = localStorage.getItem('visitor_uuid');
    this.visitId = sessionStorage.getItem('visit_id');
    this.trackPageView();
    this.setupEventListeners();
  }
  
  // ... rest of the implementation
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  window.analytics = new Analytics();
});
```

## Deployment

### Production Deployment Guidelines
```bash
# Build the application
RAILS_ENV=production rails assets:precompile  # If using assets
RAILS_ENV=production rails db:migrate         # Run any pending migrations

# Set up environment variables
# Make sure all required environment variables are set in your production environment
# See the Configuration section above for required variables
```

### Production Considerations
- Enable SSL in production
- Configure proper CORS settings
- Set up monitoring with Sentry
- Configure rate limiting
- Enable database SSL connections
- Set up proper logging
- Configure proper database backups
- Set up health monitoring
- Implement proper caching strategy

### Deployment Checklist
1. Security
   - All environment variables are properly set
   - SSL certificates are valid and installed
   - Security headers are configured
   - Database connections are secure

2. Performance
   - Database indexes are in place
   - Caching is configured
   - Rate limiting is set up
   - Background jobs are configured

3. Monitoring
   - Error tracking is set up (Sentry)
   - Performance monitoring is in place
   - Logging is properly configured
   - Alerts are set up for critical issues

## Security

Refer to [SECURITY_GUIDE.md](SECURITY_GUIDE.md) for detailed security measures and best practices.

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
- Parameter whitelisting
- Error message sanitization
- Proper error logging
- IP address validation
- User agent sanitization

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

Note: The `.env` file is ignored by Git for security. Never commit sensitive credentials to version control.