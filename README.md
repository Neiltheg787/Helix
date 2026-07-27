# Helix

Helix is a native JaC full-stack hardware engineering app. `main.jac` is the canonical JacHammer entry and mounts the single spatial client implementation, while JaC owns the backend API, graph persistence model, AI orchestration, project/version/artifact topology, lifecycle, CAD/PCB/BOM/AR/order data structures, evidence, bundle exports, and walkers.

## Architecture

- `main.jac`: Jac nodes, typed edges, walkers, `def:pub` APIs, AI structured-output functions, and backend domain structures.
- `helix_ui.tsx`: the single canonical spatial client implementation imported by `main.jac`, with the lazy Three.js viewport, prompt terminal, version tree, artifact views, AR camera fallback, and JaC API client.
- `styles.css`: the migrated cyber-spatial design system, responsive application shell, accessible states, and reduced-motion fallbacks.
- `docs/spatial-interface.md`: UI hierarchy, ownership model, and user flow.
- `helix_domain_tests.jac`: standalone Jac tests for fallback artifacts, quote math, normalization, and validation evidence.
- `jac.toml`: Jac project, npm interop, byLLM, client, and serve config.
- `Dockerfile`: production Jac service container.

The application has one frontend. `jac start` or `jac run dist/helix.jab` serves the Jac API and the same canonical client bundle. Public walkers are available under `/walker/<Name>`, and public functions are under `/function/<name>`.

## Local Development

```bash
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.34.7
export PATH="$HOME/.local/bin:$PATH"
jac install
```

Start JacHammer locally:

```bash
jac start --host 0.0.0.0 --port 8000
```

Open `http://localhost:8000`.

## Validation

```bash
jac check .
jac build
jac test helix_domain_tests.jac
```

`jac test helix_domain_tests.jac` runs the standalone domain suite. The same assertions also remain alongside the native JaC web entry in `main.jac`; `jac build` runs the whole-program check and client bundle gate.

## Production

Jac should run as a service/container:

```bash
docker build -t helix-jac .
docker run -p 8000:8000 --env-file .env helix-jac
```

The Jac service serves both the API and the canonical client. The sealed artifact is suitable for a JacHammer/container deployment:

```bash
jac build
jac run dist/helix.jab
```

## AR Notes

Jac owns AR handoff records, project authorization state, model metadata, expiration, and fallback status. Browser capability detection lives in the canonical client and degrades in this order:

WebXR -> iOS Quick Look / Android Scene Viewer -> camera preview -> interactive 3D fallback.

Current local build exposes the AR workflow and records handoffs. Real plane tracking and model export require configured CAD/AR workers.

## Client Interop

- `helix_ui.tsx`: the one TypeScript/JSX module imported by `main.jac` through Jac's supported client interop. It is not a second app or a Next.js route.
- `Dockerfile`: production container definition.
- GitHub workflow YAML: CI configuration.

The executable-source split is now about 59% JaC and 41% TypeScript/JSX by physical lines, and about 58% JaC and 42% TypeScript/JSX by bytes. CSS is reported separately because it is presentation, not application logic.
