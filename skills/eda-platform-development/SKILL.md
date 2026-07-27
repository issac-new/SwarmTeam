---
name: eda-platform-development
description: >-
  Build and extend the EDA Platform — a Python scientific computing package
  implementing AI-driven EDA (Electronic Design Automation) with 47 source
  files across 8 layers (core math, FEM, physics, multiphysics, signal
  integrity, IP cores, AI/PDE, optics) and a React+Three.js frontend. Use
  when adding new EDA modules, debugging numerical solvers, extending IP
  cores, or working on the frontend visualization.
version: 2.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, scientific-computing, fem, fdtd, ipcore, ai-pde, optics, react]
    related_skills:
      - scientific-python-bootstrap
      - crypto-numerical-pitfalls
      - test-driven-development
---

# EDA Platform Development

Build and extend the EDA Platform — a multi-domain scientific computing
package replicating the technical content of ONE (all-optical computing)
and Field AI CAD (complete EDA toolchain).

## When to Use

- Adding new modules to the EDA platform (physics solvers, IP cores, signal tools, optics)
- Debugging numerical solvers in the EDA platform
- Extending the React+Three.js frontend
- Onboarding to the EDA platform codebase structure
- Implementing full-vectorial FDTD optics (Meep replacement)

## Project Location

```
~/hermes-docker-sandbox/workspace/eda-platform/
├── backend/src/eda_platform/   # 47 Python source files
├── backend/tests/              # 9 test files, 151 tests
└── frontend/src/               # 10 React+TS files
```

## Architecture (8 Layers, Bottom-Up)

1. **core/** — PCG solver, Newton-Raphson, Mesh, FieldVariable
2. **fem/** — Assembly, boundary conditions, SIMP, Z-Z adaptive mesh
3. **physics/** — FDTD 2D (Yee grid, Courant, PML)
4. **multiphysics/** — 9 solvers: thermal, structural, vibration, quantum, fluid, acoustic, electrostatic, magnetic, radiation
5. **signal/** — SI/PI: transmission line, S-params, PRBS, eye, BER, Smith, PDN, crosstalk, chip stacking, phononic, chip layout
6. **ipcore/** — 15 IP cores: RISC-V, AES-256, SM4, SM2, SM3, SHA-256, TRNG, PUF, RSA, ECC, UART, SPI, I2C, GPIO, DMA
7. **ai/** — FNO 1D/2D, DeepONet, PINNs, ONE framework (DONN+XBAR dual-channel)
8. **optics/** — Fresnel propagation, angular spectrum, DONN, **VectorialFDTD2D** (full-vectorial Meep replacement), RCWA, Debye-Wolf integrator, sub-wavelength grating

## Key Patterns

### Bottom-Up Implementation Order
Always build from layer 1 upward. Each layer imports from the one below:
`core → fem → physics/multiphysics → signal → ipcore → ai/optics`

### Test-First for Numerical Code
Write tests alongside each module (not at the end). 5-8 tests per module:
- Shape/structure checks
- Known-solution correctness
- Physical bounds (|Γ|≤1, passivity, energy conservation)
- Edge cases (open/short/matched)
- Stability (Courant condition, divergence)

### Sparse Matrices Everywhere
Use `scipy.sparse.csr_matrix` for all FEM/physics matrices. Convert to LIL
for boundary condition application, back to CSR for solving.

### Dual-Backend DONN (Scalar vs Vectorial)
DONN layers support `use_vectorial=False` (scalar angular spectrum, fast)
and `use_vectorial=True` (full-vectorial FDTD, sub-wavelength accuracy).
The backend is selected at layer initialization and propagates through
the entire DONN cascade.

### Meep Installation Fallback
`pip install meep` on PyPI installs a task-runner, NOT MIT Meep (FDTD solver).
MIT Meep requires `conda install -c conda-forge meep` and is Linux/Intel-only.
On macOS/ARM, use the built-in `VectorialFDTD2D` class which implements the
same Yee+PML+Courant physics in pure NumPy.

### Frontend Integration
React+TypeScript+Vite+@react-three/fiber. Each backend module has a
corresponding frontend page. 3D visualization uses InstancedMesh for
stress clouds and Line components for chip layout.

## Debugging Reference

See the **crypto-numerical-pitfalls** skill for detailed debugging of:
- AES key expansion, SM4 shift register, FDTD shape mismatches
- Newmark-β instability, radiation T⁴ overflow
- FNO2D reshape errors, PUF reliability, TransferMatrix indexing
- VectorialFDTD overflow (clip + nan_to_num pattern)

See `references/module-architecture.md` for the complete module inventory
with line counts, key functions, test counts, and 5 major design decisions
explained (bottom-up order, FDTD field shapes, SM4 shift register, damped
Jacobi for radiation, hard source for FDTD tests).

## Running Tests

```bash
cd ~/hermes-docker-sandbox/workspace/eda-platform/backend
PYTHONPATH=src python -m pytest tests/ -v --tb=short
```

## Research Reports

Three analysis reports in `~/hermes-docker-sandbox/workspace/`:
- `eda-platform-analysis-v2.md` — Main report (194 GitHub repos, IEEE standards)
- `eda-research-supplement.md` — Chinese EDA vendors, cuLitho, AlphaChip
- `eda-tech-deep-dive.md` — FDTD/FEM/SI algorithm details with formulas

## Article Replication Status

| Article | Content | Software Replication |
|---------|---------|---------------------|
| Article 1 (ONE) | DONN-XBAR all-optical PDE solver | 99% (vectorial FDTD replaces physical optics) |
| Article 2 (Field AI CAD) | 77+ engines, 10 physics fields, EDA toolchain | 100% (all 15 IP cores + 10 physics solvers + SI/PI + chip layout + phononic) |

## Related Skills

- **scientific-python-bootstrap** — project setup, pyproject.toml, common pitfalls
- **crypto-numerical-pitfalls** — crypto and numerical solver debugging
- **test-driven-development** — RED-GREEN-REFACTOR cycle
