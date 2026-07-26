# Language Breakdown

Generated after the Helix JaC/original-UI migration:

- Handwritten Jac files: `main.jac`, `test_helix_domain.jac`
- Handwritten Jac lines: 1,158
- Handwritten CSS files: `styles.css`
- Handwritten JavaScript/TypeScript files: none
- Generated files: `.jac/` build output and npm/Vite client output. Do not manually edit generated files.
- Original Founder/Node0 structures represented in JaC: project workspace state, chat messages, board templates, BOM documents, CAD features/OpenSCAD parameters, Circuitron responses, AR handoff payloads, fab quote lines, order states, and tool execution progress.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac test_helix_domain.jac
find . \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path './.jac/*' -print
```
