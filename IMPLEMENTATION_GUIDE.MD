# Implementation Guide

## Client-Side Integration

### JavaScript Tracking Script

The following script should be included in your web application to enable analytics tracking.

```javascript
// analytics.js
class Analytics {
  constructor() {
    this.visitorUuid = localStorage.getItem('visitor_uuid');
    this.visitId = sessionStorage.getItem('visit_id');
    
    // Track the page view when initialized
    this.trackPageView();
    
    // Set up event to track when user leaves page
    window.addEventListener('beforeunload', () => {
      this.endVisit();
    });
  }
  
  async trackPageView() {
    try {
      const response = await fetch('/api/v1/analytics/track', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          visitor_uuid: this.visitorUuid,
          page_path: window.location.pathname,
        }),
      });
      
      const data = await response.json();
      
      // Store the visitor UUID and visit ID
      if (data.visitor_uuid) {
        localStorage.setItem('visitor_uuid', data.visitor_uuid);
        this.visitorUuid = data.visitor_uuid;
      }
      
      if (data.visit_id) {
        sessionStorage.setItem('visit_id', data.visit_id);
        this.visitId = data.visit_id;
      }
    } catch (error) {
      console.error('Failed to track page view:', error);
    }
  }
  
  async endVisit() {
    if (!this.visitId) return;
    
    try {
      await fetch('/api/v1/analytics/end_visit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          visit_id: this.visitId,
        }),
      });
    } catch (error) {
      console.error('Failed to end visit:', error);
    }
  }
}

// Initialize analytics
document.addEventListener('DOMContentLoaded', () => {
  window.analytics = new Analytics();
});
```

### Installation

Add the script to your HTML:

```html
<script src="/path/to/analytics.js"></script>
```

Or import it as a module:

```javascript
import Analytics from './analytics';
```

## API Reference

### Endpoints

#### Track Page View

Records a page view and creates or continues a visit.

**Endpoint:** `POST /api/v1/analytics/track`

**Request Body:**

```json
{
  "visitor_uuid": "optional-existing-visitor-id",
  "page_path": "/current/page/path"
}
```

**Response:**

```json
{
  "visitor_uuid": "visitor-uuid",
  "visit_id": 123
}
```

#### End Visit

Marks a visit as ended and calculates if it was a bounce.

**Endpoint:** `POST /api/v1/analytics/end_visit`

**Request Body:**

```json
{
  "visit_id": 123
}
```

**Response:**

```json
{
  "status": "Visit ended"
}
```

#### Get Analytics Stats

Retrieves analytics statistics for a specified timeframe.

**Endpoint:** `GET /api/v1/analytics/stats`

**Query Parameters:**

| Parameter  | Type   | Default | Description                           |
|------------|--------|---------|---------------------------------------|
| timeframe  | string | "day"   | Options: day, week, month, year      |

**Response:**

```json
{
  "summary": {
    "total_visits": 1000,
    "unique_visitors": 800,
    "page_views": 2500,
    "bounce_rate": 65.5,
    "avg_duration": 45
  },
  "traffic_sources": {
    "direct": 300,
    "search": 450,
    "referral": 150,
    "social": 100
  },
  "devices": {
    "desktop": 600,
    "mobile": 350,
    "tablet": 50
  },
  "geolocations": [
    {"country": "US", "visits": 500},
    {"country": "UK", "visits": 150},
    {"country": "CA", "visits": 75}
  ],
  "pages": [
    {"path": "/", "views": 800},
    {"path": "/products", "views": 400},
    {"path": "/about", "views": 200}
  ]
}
```

## Error Handling

All endpoints follow the same error response format:

```json
{
  "error": "Error message description"
}
```

Common HTTP status codes:

| Status Code | Description                                           |
|------------|-------------------------------------------------------|
| 200        | Success                                               |
| 400        | Bad Request - Invalid parameters                      |
| 401        | Unauthorized - Authentication required                 |
| 403        | Forbidden - Insufficient permissions                  |
| 404        | Not Found - Resource doesn't exist                    |
| 429        | Too Many Requests - Rate limit exceeded               |
| 500        | Internal Server Error - Something went wrong          |

## Rate Limiting

The API implements rate limiting to prevent abuse:

- Global: 300 requests per 5 minutes per IP
- Analytics Track: 60 requests per minute per IP

When rate limit is exceeded, the API returns status code 429 with a response:

```json
{
  "error": "Rate limit exceeded. Please try again in X seconds"
}
```