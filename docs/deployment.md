# Helix Deployment

## Supported Topology

Helix runs as a native Jac API service plus a Next.js frontend UI.

1. Build and run the Jac backend on a container platform such as Render, Fly.io, Railway, ECS, or Kubernetes.
2. Build the Next.js UI with `npm run build`.
3. Deploy the frontend to Vercel or another Next-compatible host and set `HELIX_JAC_ORIGIN` or `NEXT_PUBLIC_HELIX_API_URL` to the public JaC backend URL.
4. Terminate HTTPS at the platform or reverse proxy.
5. Configure optional worker URLs through environment variables.

The repository root intentionally contains `package.json`, `app/`, and `next.config.mjs` only for the frontend. It does not contain Next API routes, and production backend behavior is not a Node/Next build. The supported backend entrypoint is:

```bash
jac start --no-client --host 0.0.0.0 --port ${PORT:-8000}
```

## Commands

```bash
jac --version
jac install
jac check .
jac build
npm ci
npm run build
jac start --no-client --host 0.0.0.0 --port 8000
```

## Render

`render.yaml` is included for a Docker-backed web service. Create a Render blueprint from this repository, then set optional secrets in the Render dashboard.

## Fly.io

`fly.toml` is included for a Docker-backed Fly app. Set a unique app name and run:

```bash
fly launch --no-deploy
fly deploy
```

## Kubernetes

Jac also documents Kubernetes deployment through:

```bash
jac start --scale --target kubernetes
```

That path requires a configured Kubernetes cluster, image registry, and credentials. Without those credentials, the command should not be reported as deployed.

## Health Check

POST `/walker/Health`

Expected report:

```json
{"ok": true, "service": "helix-jac", "architecture": "native-jac"}
```

## CORS

For managed deployment, configure `HELIX_JAC_ORIGIN` for Next rewrites or configure the Jac reverse proxy/CORS layer to allow the production frontend origin to call `/walker/*` and `/function/*` endpoints over HTTPS.
