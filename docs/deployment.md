# Helix Deployment

## Supported Topology

Helix runs as one native Jac service. JacHammer serves the API and the canonical client bundle generated from `main.jac`.

1. Install the pinned Jac 0.34.7 toolchain and run `jac install`.
2. Run `jac check .`, `jac test helix_domain_tests.jac`, and `jac build`.
3. Run the sealed `dist/helix.jab` with JacHammer or start `jac start` on a container platform such as Render, Fly.io, Railway, ECS, or Kubernetes.
4. Terminate HTTPS at the platform or reverse proxy.
5. Configure optional worker URLs through environment variables.

The repository root has no Next.js app or competing Vercel entrypoint. The supported full-stack entrypoint is:

```bash
jac start --host 0.0.0.0 --port ${PORT:-8000}
```

## Commands

```bash
jac --version
jac install
jac check .
jac build
jac test helix_domain_tests.jac
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

For managed deployment, configure `HELIX_PUBLIC_ORIGIN` on the Jac service or reverse proxy when CORS is needed. Same-origin deployment is the default and requires no browser API URL variable.
