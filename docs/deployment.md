# Helix Deployment

## Supported Topology

Helix runs as a native Jac service.

1. Build and run the Jac container on a container platform such as Render, Fly.io, Railway, ECS, or Kubernetes.
2. Terminate HTTPS at the platform or reverse proxy.
3. Configure any optional worker URLs through environment variables.
4. If Vercel is used, deploy only an optional static frontend shell and point it at the Jac API. Do not use `next build` as the Helix production build.

The repository root intentionally does not contain `package.json`, `next.config.*`, `src/`, `app/`, or `pages/`. Production is not a Node/Next build. The supported production entrypoint is:

```bash
jac start --host 0.0.0.0 --port ${PORT:-8000}
```

## Commands

```bash
jac --version
jac install
jac check .
jac test test_helix_domain.jac
jac build
jac start --host 0.0.0.0 --port 8000
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

For managed deployment, configure the reverse proxy or platform CORS layer to allow the production frontend origin to call `/walker/*` and `/function/*` endpoints over HTTPS.
