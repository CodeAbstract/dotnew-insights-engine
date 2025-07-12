# Next.js Integration Guide

This guide explains how to integrate the DotNew Insights Engine with a Next.js application. This guide works for both TypeScript and JavaScript projects.

## Installation

First, create a configuration file for your analytics endpoints:

```typescript
// src/config/analytics.ts (or .js)
const config = {
  development: {
    apiBaseUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1',
  },
  production: {
    apiBaseUrl: process.env.NEXT_PUBLIC_API_URL || 'https://your-api-domain.com/api/v1',
  },
};

export default config[process.env.NODE_ENV || 'development'];
```

## Analytics Hook

Create a custom hook to handle analytics tracking:

```typescript
// src/hooks/useAnalytics.ts (or .js)
import { useEffect } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import config from '@/config/analytics';

export const useAnalytics = () => {
  const pathname = usePathname();
  const searchParams = useSearchParams();

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
    // Only run on client side
    if (typeof window === 'undefined') return;

    // Track page view when pathname changes
    trackPageView(pathname);

    // End visit when user leaves
    const handleBeforeUnload = () => {
      endVisit();
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [pathname, searchParams]); // Include searchParams if you want to track query parameter changes

  return { trackPageView };
};
```

## Usage in App Layout

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
        <Analytics /> {/* Add this component */}
        {children}
      </body>
    </html>
  );
}
```

Create the Analytics component:

```typescript
// src/components/Analytics.tsx (or .jsx)
'use client';

import { useAnalytics } from '@/hooks/useAnalytics';

export function Analytics() {
  useAnalytics(); // This will automatically track page views
  return null;
}
```

## Analytics Dashboard Component

```typescript
// src/components/AnalyticsDashboard.tsx (or .jsx)
'use client';

import { useState, useEffect } from 'react';
import config from '@/config/analytics';

interface AnalyticsStats {
  total_visits: number;
  unique_visitors: number;
  page_views: number;
  bounce_rate: number;
  avg_duration: number;
}

export function AnalyticsDashboard() {
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
}
```

## Environment Setup

Create `.env.local` file:

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
```

For production, set the environment variable in your hosting platform (Vercel, etc.):

```bash
NEXT_PUBLIC_API_URL=https://your-api-domain.com/api/v1
```

## API Routes (Optional)

If you want to proxy the analytics requests through your Next.js app:

```typescript
// src/app/api/analytics/track/route.ts
import { NextResponse } from 'next/server';
import config from '@/config/analytics';

export async function POST(request: Request) {
  try {
    const data = await request.json();
    
    const response = await fetch(`${config.apiBaseUrl}/analytics/track`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    const result = await response.json();
    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to track analytics' },
      { status: 500 }
    );
  }
}
```

## Error Handling

Create a utility for error handling:

```typescript
// src/utils/errorHandling.ts (or .js)
export const logError = (error: Error, context: string) => {
  // Integrate with your error tracking service (e.g., Sentry)
  console.error(`[${context}]`, error);
};

// Usage in useAnalytics.ts:
import { logError } from '@/utils/errorHandling';

catch (error) {
  logError(error as Error, 'Analytics Tracking');
}
```

## Testing

```typescript
// src/hooks/__tests__/useAnalytics.test.ts (or .js)
import { renderHook } from '@testing-library/react';
import { useAnalytics } from '../useAnalytics';

jest.mock('next/navigation', () => ({
  usePathname: () => '/test-path',
  useSearchParams: () => new URLSearchParams(),
}));

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

## Using with Middleware (Optional)

If you need to add analytics-related headers or handle analytics at the edge:

```typescript
// src/middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Clone the response
  const response = NextResponse.next();

  // Add custom headers if needed
  response.headers.set('X-Analytics-Version', '1.0');

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|public/).*)',
  ],
};
```

## Using with App Router

The above implementation works with App Router, but here's how to add analytics to specific pages:

```typescript
// src/app/page.tsx
import { AnalyticsDashboard } from '@/components/AnalyticsDashboard';

export default function HomePage() {
  return (
    <main>
      <h1>Welcome</h1>
      <AnalyticsDashboard />
    </main>
  );
}
```

## Using with API Routes

If you're using the App Router's API routes:

```typescript
// src/app/api/analytics/stats/route.ts
import { NextResponse } from 'next/server';
import config from '@/config/analytics';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const timeframe = searchParams.get('timeframe') || 'day';

  try {
    const response = await fetch(
      `${config.apiBaseUrl}/analytics/stats?timeframe=${timeframe}`,
      {
        credentials: 'include',
      }
    );

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch analytics' },
      { status: 500 }
    );
  }
}
``` 