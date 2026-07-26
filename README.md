# Helix

Helix is an AI-native hardware engineering workspace for generating and inspecting CAD, PCB/schematic artifacts, firmware, BOMs, AR previews, collaboration state, and manufacturing quotes.

## Preserved Capabilities

- Streaming OpenAI hardware copilot with tool progress and stop control.
- OpenSCAD/CAD document generation, parameter editing, Three.js preview, and SCAD export.
- PCBFlow/Circuitron-backed PCB and schematic artifact handling with real error disclosure.
- Firmware editor with generated code persistence and download.
- BOM editing, validation warnings, CSV export, and prototype quote inputs.
- Supabase-backed auth/workspace/team/order/AR handoff routes when configured.
- Deliberate local/demo mode when Supabase is not configured.
- Stripe Checkout, verification, and webhook routes with server-side pricing.
- AR route with WebXR/native/fallback paths and camera cleanup in fallback viewers.

## New Helix Work

- Product renamed to Helix across visible copy, metadata, health output, prompts, docs, and generated filenames.
- Premium white engineering workspace shell with Build, Projects, Templates, Component Library, Manufacturing Orders, Team, and Settings navigation.
- Helix code-native logo/wordmark.
- Dedicated AR compatibility utility with tests for secure context, WebXR, iOS Quick Look, Android Scene Viewer, camera API, and permission denial.
- `HELIX_*` PCBFlow environment names with legacy `NODE0_*` fallbacks.
- Accurate `.env.example` with required/optional, public/server, format, feature, and missing-service behavior.

## Local Startup

```bash
npm install
npm run build
npm run start
```

Development:

```bash
npm run dev
```

Optional PCBFlow setup:

```bash
npm run setup:pcbflow
```

## Validation

Useful checks:

```bash
npx tsc --noEmit
npm run lint
npm run test:ar-compatibility
npm run test:cadam:context
npm run test:erc-summary
npm run build
```

OpenAI-dependent checks require `OPENAI_API_KEY`:

```bash
npm run test:cadam:codegen
npm run test:pcbflow
```

Circuitron MCP check requires a running MCP service:

```bash
npm run check:circuitron-mcp
```

## Deployment

Vercel works for the Next app and server routes. Circuitron/PCBFlow routes need a compatible Python/MCP/Docker environment, so use Render/Docker or a remote Circuitron MCP when those features are required in production.

For Docker:

```bash
docker build -t helix .
docker run --rm -p 3000:3000 -e OPENAI_API_KEY=sk-... helix
```

## AR Notes

Helix uses progressive enhancement:

1. WebXR immersive-ar when supported in a secure context.
2. iOS Quick Look with USDZ where possible.
3. Android Scene Viewer/WebXR-capable mobile paths where available.
4. Camera-based browser preview when camera access is available.
5. Interactive 3D orbit fallback when AR/camera support is unavailable or denied.

The fallback overlays a model on camera video and does not claim real plane detection.

## Known Infrastructure Limits

- AI generation, transcription, suggestions, CAD codegen, and PCBFlow generation require `OPENAI_API_KEY`.
- Cloud sync/auth/team persistence requires Supabase configuration and the existing migrations.
- Stripe checkout requires `STRIPE_SECRET_KEY`; webhooks require `STRIPE_WEBHOOK_SECRET`.
- Circuitron/KiCad validation requires Circuitron CLI/MCP and related local or remote dependencies.
- The production build currently reports a Turbopack NFT tracing warning from the dynamic Circuitron subprocess import path; the build completes successfully.
