# Helix

Helix is a JaC-backed hardware engineering app with a production React UI. JaC owns the backend API, graph persistence model, AI orchestration, project/version/artifact topology, CAD/PCB/BOM/AR/order data structures, and walkers. React/TypeScript owns the polished browser UI.

## Architecture

- `main.jac`: Jac nodes, typed edges, walkers, `def:pub` APIs, AI structured-output functions, and backend domain structures.
- `ui/src`: React/TypeScript UI that calls the JaC `/function/*` and `/walker/*` endpoints.
- `package.json`, `vite.config.ts`: UI development/build tooling.
- `styles.css`: legacy JaC client styling kept for the built-in JaC app shell.
- `test_helix_domain.jac`: Jac tests for graph domain behavior.
- `jac.toml`: Jac project, npm interop, byLLM, client, and serve config.
- `Dockerfile`: production Jac service container.

The application is intentionally not a Next.js backend. In the preferred split mode, `jac start --no-client` serves the API and Vite serves the React UI. Public walkers are available under `/walker/<Name>`, and public functions are under `/function/<name>`.

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

Open `http://localhost:5173`.

## Validation

```bash
jac check .
jac build
npm run build
```

`jac test main.jac` currently hits a JaC 0.34.7 client-test harness issue resolving `styles.css` from a temporary directory. Domain tests are embedded in `main.jac`; `jac build` still runs the whole-program check and client bundle gate.

## Production

Jac should run as a service/container:

```bash
docker build -t helix-jac .
docker run -p 8000:8000 --env-file .env helix-jac
```

If a static marketing shell is deployed to Vercel later, it should call this Jac service over HTTPS. The Jac backend should not be replaced by `next build`.

The project now has a `package.json` on purpose for the React UI. It is not a Next.js app and must not run `next build`.

## AR Notes

Jac owns AR handoff records, project authorization state, model metadata, expiration, and fallback status. Browser capability detection can live in the React UI and should degrade in this order:

WebXR -> iOS Quick Look / Android Scene Viewer -> camera preview -> interactive 3D fallback.

Current local build exposes the AR workflow and records handoffs. Real plane tracking and model export require configured CAD/AR workers.

## Non-Jac Code

- `ui/src`: React/TypeScript UI.
- `styles.css`: legacy JaC client presentation.
- `Dockerfile`: production container definition.
- GitHub workflow YAML: CI configuration.

Current target split is roughly 60% JaC backend/domain and 40% React/TypeScript UI.
