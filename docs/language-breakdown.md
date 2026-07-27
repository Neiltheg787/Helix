# Language Breakdown

Generated after the Helix Next.js UI migration:

- Handwritten Jac files: `main.jac`, `test_helix_domain.jac`
- Handwritten Jac lines: 1,158
- Handwritten Next.js/TypeScript files: `app/page.tsx`, `app/layout.tsx`, `next-env.d.ts`
- Handwritten Next.js/TypeScript lines: 726
- Current application-code split, excluding CSS/config/docs/generated files: about 62% JaC and 38% Next.js/TypeScript.
- Handwritten CSS files: `styles.css`, `app/globals.css`
- Generated files: `.jac/`, `.next/`, `dist/`, and dependency output. Do not manually edit generated files.
- Original Founder/Node0 structures represented in JaC: project workspace state, chat messages, board templates, BOM documents, CAD features/OpenSCAD parameters, Circuitron responses, AR handoff payloads, fab quote lines, order states, and tool execution progress.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac test_helix_domain.jac
find . \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path './.jac/*' -not -path './.next/*' -not -path './dist-ui/*' -not -path './node_modules/*' -print
```
