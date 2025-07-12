# React JavaScript Integration Guide

This guide explains how to integrate the DotNew Insights Engine with a React application using JavaScript.

## Installation

First, create a configuration file for your analytics endpoints:

```javascript
// src/config/analytics.js
const config = {
  development: {
    apiBaseUrl: 'http://localhost:3000/api/v1',
  },
  production: {
    apiBaseUrl: process.env.REACT_APP_API_URL || 'https://your-api-domain.com/api/v1',
  },
};

export default config[process.env.NODE_ENV || 'development'];
```

## Analytics Hook

Create a custom hook to handle analytics tracking:

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

      if (!response.ok) {
        throw new Error('Failed to track page view');
      }

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

  const endVisit = async () => {
    const visitId = sessionStorage.getItem('visit_id');
    if (!visitId) return;

    try {
      await fetch(`${config.apiBaseUrl}/analytics/end_visit`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ visit_id: parseInt(visitId, 10) }),
      });
    } catch (error) {
      console.error('Failed to end visit:', error);
    }
  };

  useEffect(() => {
    // Track page view when location changes
    trackPageView(location.pathname);

    // End visit when user leaves
    const handleBeforeUnload = () => {
      endVisit();
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [location.pathname]);

  return { trackPageView };
};
```

## Usage in Components

### Basic Usage

```javascript
// src/App.js
import { useAnalytics } from './hooks/useAnalytics';

function App() {
  useAnalytics(); // This will automatically track page views

  return (
    <div>
      {/* Your app content */}
    </div>
  );
}

export default App;
```

### Manual Tracking

```javascript
// src/components/CustomTracker.js
import { useAnalytics } from './hooks/useAnalytics';

function CustomTracker() {
  const { trackPageView } = useAnalytics();

  const handleCustomEvent = async () => {
    await trackPageView('/virtual/custom-event');
  };

  return (
    <button onClick={handleCustomEvent}>
      Track Custom Event
    </button>
  );
}

export default CustomTracker;
```

### Analytics Dashboard Component

```javascript
// src/components/AnalyticsDashboard.js
import { useState, useEffect } from 'react';
import config from '../config/analytics';

function AnalyticsDashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await fetch(`${config.apiBaseUrl}/analytics/stats?timeframe=day`, {
          credentials: 'include',
        });
        
        if (!response.ok) {
          throw new Error('Failed to fetch analytics');
        }

        const data = await response.json();
        setStats(data);
      } catch (err) {
        setError(err.message || 'Failed to fetch analytics');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) return <div>Loading analytics...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!stats) return <div>No data available</div>;

  return (
    <div>
      <h2>Analytics Dashboard</h2>
      <div>
        <p>Total Visits: {stats.total_visits}</p>
        <p>Unique Visitors: {stats.unique_visitors}</p>
        <p>Page Views: {stats.page_views}</p>
        <p>Bounce Rate: {stats.bounce_rate}%</p>
        <p>Average Duration: {stats.avg_duration} seconds</p>
      </div>
    </div>
  );
}

export default AnalyticsDashboard;
```

## Environment Setup

Add the following to your `.env` files:

```bash
# .env.development
REACT_APP_API_URL=http://localhost:3000/api/v1

# .env.production
REACT_APP_API_URL=https://your-api-domain.com/api/v1
```

## Error Handling

The analytics hooks include basic error handling, but you might want to integrate with your application's error tracking system:

```javascript
// src/services/errorTracking.js
export const logError = (error, context) => {
  // Integrate with your error tracking service (e.g., Sentry)
  console.error(`[${context}]`, error);
};

// Update useAnalytics.js to use error tracking
import { logError } from '../services/errorTracking';

// In catch blocks:
catch (error) {
  logError(error, 'Analytics Tracking');
}
```

## Testing

Here's how to test your analytics integration:

```javascript
// src/hooks/__tests__/useAnalytics.test.js
import { renderHook } from '@testing-library/react-hooks';
import { useAnalytics } from '../useAnalytics';

describe('useAnalytics', () => {
  beforeEach(() => {
    // Clear storage before each test
    localStorage.clear();
    sessionStorage.clear();
  });

  it('should track page view', async () => {
    const { result } = renderHook(() => useAnalytics());
    const response = await result.current.trackPageView('/test');
    
    expect(response).toHaveProperty('visitor_uuid');
    expect(response).toHaveProperty('visit_id');
  });

  // Add more tests...
});
```

## Using with Axios

If you prefer using Axios over fetch, here's how to set it up:

```javascript
// src/services/api.js
import axios from 'axios';
import config from '../config/analytics';

const api = axios.create({
  baseURL: config.apiBaseUrl,
  withCredentials: true,
});

export const trackPageView = async (data) => {
  const response = await api.post('/analytics/track', data);
  return response.data;
};

export const endVisit = async (visitId) => {
  const response = await api.post('/analytics/end_visit', { visit_id: visitId });
  return response.data;
};

export const getStats = async (timeframe = 'day') => {
  const response = await api.get(`/analytics/stats?timeframe=${timeframe}`);
  return response.data;
};
``` 