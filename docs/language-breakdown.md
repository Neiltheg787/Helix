# Language Breakdown

Generated after the Helix spatial workspace rebuild:

- Handwritten Jac files: `main.jac`, `helix_domain_tests.jac`
- Handwritten Jac lines: 1,838
- Handwritten Next.js/TypeScript files: `app/page.tsx`, `app/layout.tsx`, `next-env.d.ts`
- Handwritten Next.js/TypeScript lines: 1,731
- Current executable application-code split, excluding CSS/config/docs/generated files: about 52% JaC and 48% Next.js/TypeScript by physical lines.
- The same split by source bytes is about 52% JaC and 48% TypeScript.
- Handwritten CSS files: `styles.css`, `app/globals.css`
- Generated files: `.jac/`, `.next/`, `dist/`, and dependency output. Do not manually edit generated files.
- JaC-owned structures include projects, lifecycle, activity history, typed artifact graphs, versions, version comparison, chat, templates, BOM, CAD/OpenSCAD parameters, Circuitron, readiness evidence, AR handoffs, authoritative quotes, orders, and source-bundle manifests.
- TypeScript owns the Three.js renderer, camera/orbit controls, responsive shell, command palette, browser capability detection, microphone input, local UI telemetry preview, and artifact visualization.
- CSS is intentionally excluded from the executable ownership ratio and documented separately. Counting presentation rules as backend or frontend logic would misrepresent the architecture.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac helix_domain_tests.jac
find . \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path './.jac/*' -not -path './.next/*' -not -path './dist-ui/*' -not -path './node_modules/*' -print
```
