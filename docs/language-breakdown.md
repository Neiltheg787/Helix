# Language Breakdown

Generated after the canonical JacHammer client migration:

- Handwritten Jac files: `main.jac`, `helix_domain_tests.jac`
- Handwritten Jac lines: 2,463
- Canonical client interop file: `helix_ui.tsx`
- Handwritten TypeScript/JSX lines: 1,703
- Current executable application-code split, excluding CSS/config/docs/generated files: about 59% JaC and 41% TypeScript/JSX by physical lines.
- The same split by source bytes is about 58% JaC and 42% TypeScript/JSX.
- Handwritten CSS file: `styles.css`, imported by `main.jac`
- Generated files: `.jac/`, `dist/`, and dependency output. Do not manually edit generated files.
- JaC-owned structures include projects, lifecycle, activity history, typed artifact graphs, versions, version comparison, chat, templates, BOM, CAD/OpenSCAD parameters, Circuitron, readiness evidence, AR handoffs, authoritative quotes, orders, source-bundle manifests, project search, artifact manifests, dependency disclosures, health reports, command availability, collaboration state, order history, save checkpoints, and version timelines.
- The canonical client interop module owns the Three.js renderer, camera/orbit controls, responsive shell, command palette, browser capability detection, microphone input, local UI telemetry preview, and artifact visualization. It is mounted only through `main.jac`; there is no Next.js copy.
- CSS is intentionally excluded from the executable ownership ratio and documented separately. Counting presentation rules as backend or frontend logic would misrepresent the architecture.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac helix_domain_tests.jac
wc -l helix_ui.tsx
```
