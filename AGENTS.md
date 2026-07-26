# Helix Jac Instructions

Helix is a native Jac full-stack project. Keep application logic in `.jac` files.

- Use `~/.local/bin/jac check .` before committing.
- Use `~/.local/bin/jac test` for domain tests.
- Use `~/.local/bin/jac build` to build the Jac client/server bundle.
- Do not reintroduce Next.js as the backend.
- Keep browser-only AR/WebXR/camera code inside Jac client code or small documented interop modules.
