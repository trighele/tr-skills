import { render, screen } from '@testing-library/react';
import { afterEach, expect, test, vi } from 'vitest';

import { App } from './App';

afterEach(() => {
  vi.unstubAllGlobals();
});

test('shows the api as ok when its health endpoint answers', async () => {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('{"status":"ok"}')));

  render(<App />);

  expect(await screen.findByText('API: ok')).toBeInTheDocument();
});

test('shows the api as unreachable when the request fails', async () => {
  vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('network down')));

  render(<App />);

  expect(await screen.findByText('API: unreachable')).toBeInTheDocument();
});
