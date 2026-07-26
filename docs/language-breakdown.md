# Language Breakdown

Generated after the migration:

- Handwritten Jac files: `main.jac`, `test_helix_domain.jac`
- Handwritten CSS files: `styles.css`
- Handwritten JavaScript/TypeScript files: none
- Generated files: `.jac/` build output and npm/Vite client output. Do not manually edit generated files.

To refresh counts:

```bash
find . -name '*.jac' -not -path './.jac/*' -print
wc -l main.jac test_helix_domain.jac
find . \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' \) -not -path './.jac/*' -print
```
