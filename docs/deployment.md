# Helix Deployment

## Supported Topology

Helix runs as a native Jac service.

1. Build and run the Jac container on a container platform such as Render, Fly.io, Railway, ECS, or Kubernetes.
2. Terminate HTTPS at the platform or reverse proxy.
3. Configure any optional worker URLs through environment variables.
4. If Vercel is used, deploy only an optional static frontend shell and point it at the Jac API. Do not use `next build` as the Helix production build.

## Commands

```bash
jac install
jac check .
jac test test_helix_domain.jac
jac build
jac start --port 8000
```

## Health Check

POST `/walker/Health`

Expected report:

```json
{"ok": true, "service": "helix-jac", "architecture": "native-jac"}
```

## CORS

For managed deployment, configure the reverse proxy or platform CORS layer to allow the production frontend origin to call `/walker/*` and `/function/*` endpoints over HTTPS.
