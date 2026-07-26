# Helix

Helix is now a native Jac application for AI-native hardware engineering. The primary source is `main.jac`, which owns the backend API, graph persistence model, AI orchestration, project/version/artifact topology, and the Jac client UI.

## Architecture

- `main.jac`: Jac nodes, typed edges, walkers, `def:pub` APIs, AI structured-output functions, and client components.
- `styles.css`: UI styling imported by the Jac client compiler.
- `test_helix_domain.jac`: Jac tests for graph domain behavior.
- `jac.toml`: Jac project, npm interop, byLLM, client, and serve config.
- `Dockerfile`: production Jac service container.

The application is intentionally not a Next.js backend. `jac start` serves both the API and the generated client. Public walkers are available under `/walker/<Name>`, and the client entrypoint is configured through `[serve].base_route_app = "app"`.

## Local Development

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.34.7
export PATH="$HOME/.local/bin:$PATH"
jac install
jac start --dev
```

Open `http://localhost:8000/cl/app`.

## Validation

```bash
jac check .
jac test test_helix_domain.jac
jac build
```

## Production

Jac should run as a service/container:

```bash
docker build -t helix-jac .
docker run -p 8000:8000 --env-file .env helix-jac
```

If a static marketing shell is deployed to Vercel later, it should call this Jac service over HTTPS. The Jac backend should not be replaced by `next build`.

The project has no `package.json` on purpose. A host that tries to run `npm install`, `next build`, or a Vercel Next.js build is using stale deployment settings and is not deploying Helix.

## AR Notes

Jac owns AR handoff records, project authorization state, model metadata, expiration, and fallback status. Browser capability detection is implemented in Jac client code and degrades in this order:

WebXR -> iOS Quick Look / Android Scene Viewer -> camera preview -> interactive 3D fallback.

Current local build exposes the AR workflow and records handoffs. Real plane tracking and model export require configured CAD/AR workers.

## Non-Jac Code

- `styles.css`: required for browser presentation.
- `Dockerfile`: production container definition.
- GitHub workflow YAML: CI configuration.

No handwritten JavaScript or TypeScript application files remain.
