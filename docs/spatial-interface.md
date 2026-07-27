# Helix Spatial Interface

## Architecture

Helix is a workspace-first application. It opens directly into a full-height
engineering surface instead of placing a marketing page in front of the tools.

```text
Global bar: project / active version / sync / undo / redo / export
├── Tool rail: Design / PCB / Schematic / Firmware / BOM / Validation / AR / Manufacturing
├── Kinetic canvas
│   ├── Lazy Three.js assembly or focused artifact workspace
│   ├── Spatial HUD and evidence state
│   ├── Prompt terminal with voice, attachments, token estimate, and stop control
│   └── JaC-backed generative version tree
└── Sol Core
    ├── Truthfully labeled local interface telemetry
    ├── CAD parameter and assembly-layer inspector
    └── Persisted JaC conversation and tool progress
```

## Ownership

JaC owns durable and authoritative product behavior: project lifecycle, graph
persistence, AI/fallback generation, artifact versions, restore, CAD data, PCB
planning state, firmware source, BOM normalization, validation evidence, AR
handoff records, quote calculation, activity history, and source bundles.

Next.js owns browser behavior: Three.js rendering, camera/orbit interaction,
responsive panel state, command search, microphone transcription when supported,
local file selection, approximate token counting, downloads, and camera preview.

Sol Core cognitive load, token rate, and specialist activity are explicitly
labeled as a local interface simulation because the current JaC endpoint does
not expose streaming inference telemetry. Validation and manufacturing states
never claim success without backend evidence.

## User Flow

1. Select one of the design systems or edit the terminal instruction.
2. Run the instruction to create a JaC project and deterministic fallback when
   no AI provider is configured.
3. Inspect generated CAD, PCB, schematic, CircuitPython, BOM, validation, AR,
   and quote artifacts without leaving the canvas.
4. Generate another version, scrub the version tree, or use undo/redo to restore
   a real prior artifact graph.
5. Export the active source artifact. Unsupported STL, STEP, KiCad validation,
   firmware builds, and Stripe checkout remain clearly disclosed.

## Responsive Model

Desktop uses a compact icon rail, full-bleed canvas, and 344px Sol Core dock.
Tablet and mobile convert Sol Core to an opt-in overlay, place the tool rail at
the bottom, and keep the prompt and timeline above it without page scrolling.
Reduced-motion users receive static waveform, activity, and entrance states.
