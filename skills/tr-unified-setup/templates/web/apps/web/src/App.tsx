import { useEffect, useState } from 'react';

type ApiState = 'checking' | 'ok' | 'unreachable';

// A relative path, always: the api shares this component's origin, behind the router and
// behind Vite's dev proxy alike, so there is no base URL to configure.
const API_HEALTH = '/api/healthz';

export function App() {
  const [api, setApi] = useState<ApiState>('checking');

  useEffect(() => {
    fetch(API_HEALTH)
      .then(response => setApi(response.ok ? 'ok' : 'unreachable'))
      .catch(() => setApi('unreachable'));
  }, []);

  return (
    <main>
      <h1>__APP_NAME__</h1>
      <p>API: {api}</p>
    </main>
  );
}
