# Helix

Helix is a JaC-backed hardware engineering app with a production Next.js/TypeScript spatial UI. JaC owns the backend API, graph persistence model, AI orchestration, project/version/artifact topology, lifecycle, CAD/PCB/BOM/AR/order data structures, evidence, bundle exports, and walkers. Next.js owns browser interaction and visualization only.

## Architecture

- `main.jac`: Jac nodes, typed edges, walkers, `def:pub` APIs, AI structured-output functions, and backend domain structures.
- `app/page.tsx`: single production Next.js spatial workspace with a lazy Three.js viewport, prompt terminal, version tree, artifact views, AR camera fallback, and JaC API client.
- `app/globals.css`: cyber-spatial design system, responsive application shell, accessible states, and reduced-motion fallbacks.
- `docs/spatial-interface.md`: UI hierarchy, ownership model, and user flow.
- `next.config.mjs`: frontend rewrites to the JaC API service; no Next API routes are used.
- `package.json`: UI development/build tooling.
- `styles.css`: legacy JaC client styling kept for the built-in JaC app shell.
- `helix_domain_tests.jac`: standalone Jac tests for fallback artifacts, quote math, normalization, and validation evidence.
- `jac.toml`: Jac project, npm interop, byLLM, client, and serve config.
- `Dockerfile`: production Jac service container.

The application is intentionally not a Next.js backend. In the preferred split mode, `jac start --no-client` serves the API and Next.js serves the UI. Public walkers are available under `/walker/<Name>`, and public functions are under `/function/<name>`.

## Local Development

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.34.7
export PATH="$HOME/.local/bin:$PATH"
jac install
npm install
```

Start the backend:

```bash
jac start --no-client --host 0.0.0.0 --port 8000
```

Start the UI:

```bash
npm run dev
```

Open `http://localhost:3000`.

## Validation

```bash
jac check .
jac build
npm run build
```

`jac test helix_domain_tests.jac` runs the standalone domain suite. The same assertions also remain alongside the native JaC web entry in `main.jac`; `jac build` runs the whole-program check and client bundle gate.

## Production

Jac should run as a service/container:

```bash
docker build -t helix-jac .
docker run -p 8000:8000 --env-file .env helix-jac
```

If the Next UI is deployed to Vercel, it should call this Jac service over HTTPS. The Jac backend should not be replaced by Next API routes or client-only mocks.

The project has a `package.json` on purpose for the Next.js UI. `npm run build` builds only the frontend; JaC remains the backend service.

## AR Notes

Jac owns AR handoff records, project authorization state, model metadata, expiration, and fallback status. Browser capability detection can live in the React UI and should degrade in this order:

WebXR -> iOS Quick Look / Android Scene Viewer -> camera preview -> interactive 3D fallback.

Current local build exposes the AR workflow and records handoffs. Real plane tracking and model export require configured CAD/AR workers.

## Non-Jac Code

- `app/page.tsx`, `app/layout.tsx`, `app/globals.css`: Next.js/TypeScript UI.
- `styles.css`: legacy JaC client presentation.
- `Dockerfile`: production container definition.
- GitHub workflow YAML: CI configuration.

The executable-source split is now about 61% JaC and 39% Next.js/TypeScript by physical lines and bytes. CSS is reported separately because it is presentation, not application logic.
