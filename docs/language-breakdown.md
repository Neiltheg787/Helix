# Language Breakdown

Generated after the Helix split UI migration:

- Handwritten Jac files: `main.jac`, `test_helix_domain.jac`
- Handwritten Jac lines: 1,158
- Handwritten React/TypeScript files: `ui/src/App.tsx`, `ui/src/api.ts`, `ui/src/vite-env.d.ts`, `vite.config.ts`
- Handwritten React/TypeScript lines: 270
- Current application-code split, excluding CSS/config/docs/generated files: about 81% JaC and 19% React/TypeScript.
- Handwritten CSS files: `styles.css`, `ui/src/styles.css`
- Generated files: `.jac/` build output and npm/Vite client output. Do not manually edit generated files.
- Original Founder/Node0 structures represented in JaC: project workspace state, chat messages, board templates, BOM documents, CAD features/OpenSCAD parameters, Circuitron responses, AR handoff payloads, fab quote lines, order states, and tool execution progress.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac test_helix_domain.jac
find . \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path './.jac/*' -not -path './node_modules/*' -not -path './dist-ui/*' -print
```
