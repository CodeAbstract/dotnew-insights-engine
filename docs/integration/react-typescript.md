# React TypeScript Integration Guide

This guide explains how to integrate the DotNew Insights Engine with a React application using TypeScript.

## Installation

First, create a configuration file for your analytics endpoints:

```typescript
// src/config/analytics.ts
interface AnalyticsConfig {
  apiBaseUrl: string;
}

const config: Record<string, AnalyticsConfig> = {
  development: {
    apiBaseUrl: 'http://localhost:3000/api/v1',
  },
  production: {
    apiBaseUrl: process.env.REACT_APP_API_URL || 'https://your-api-domain.com/api/v1',
  },
};

export default config[process.env.NODE_ENV || 'development'];
```

## Types

Create types for your analytics data:

```typescript
// src/types/analytics.ts
export interface VisitData {
  visitor_uuid?: string;
  visit_id?: number;
}

export interface PageViewData {
  page_path: string;
  visitor_uuid?: string;
}

export interface AnalyticsStats {
  total_visits: number;
  unique_visitors: number;
  page_views: number;
  bounce_rate: number;
  avg_duration: number;
}
```

## Analytics Hook

Create a custom hook to handle analytics tracking:

```typescript
// src/hooks/useAnalytics.ts
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import config from '../config/analytics';
import type { VisitData, PageViewData } from '../types/analytics';

export const useAnalytics = () => {
  const location = useLocation();

  const trackPageView = async (path: string): Promise<VisitData> => {
    try {
      const visitorUuid = localStorage.getItem('visitor_uuid');
      const data: PageViewData = {
        page_path: path,
        visitor_uuid: visitorUuid || undefined,
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

      const result: VisitData = await response.json();

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

  const endVisit = async (): Promise<void> => {
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

```typescript
// src/App.tsx
import { useAnalytics } from './hooks/useAnalytics';

const App: React.FC = () => {
  useAnalytics(); // This will automatically track page views

  return (
    <div>
      {/* Your app content */}
    </div>
  );
};

export default App;
```

### Manual Tracking

```typescript
// src/components/CustomTracker.tsx
import { useAnalytics } from './hooks/useAnalytics';

const CustomTracker: React.FC = () => {
  const { trackPageView } = useAnalytics();

  const handleCustomEvent = async () => {
    await trackPageView('/virtual/custom-event');
  };

  return (
    <button onClick={handleCustomEvent}>
      Track Custom Event
    </button>
  );
};
```

### Analytics Dashboard Component

```typescript
// src/components/AnalyticsDashboard.tsx
import { useState, useEffect } from 'react';
import config from '../config/analytics';
import type { AnalyticsStats } from '../types/analytics';

const AnalyticsDashboard: React.FC = () => {
  const [stats, setStats] = useState<AnalyticsStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
        setError(err instanceof Error ? err.message : 'Failed to fetch analytics');
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
};

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

```typescript
// src/services/errorTracking.ts
export const logError = (error: Error, context: string) => {
  // Integrate with your error tracking service (e.g., Sentry)
  console.error(`[${context}]`, error);
};

// Update useAnalytics.ts to use error tracking
import { logError } from '../services/errorTracking';

// In catch blocks:
catch (error) {
  logError(error as Error, 'Analytics Tracking');
}
```

## Testing

Here's how to test your analytics integration:

```typescript
// src/hooks/__tests__/useAnalytics.test.tsx
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