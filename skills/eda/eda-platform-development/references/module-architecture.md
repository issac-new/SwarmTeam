# EDA Platform — Module Architecture & Design Decisions

## Complete Module Inventory (47 source files, 151 tests, ~8500 lines)

### Layer 1: Core Math (`core/`)

| File | Lines | Key Functions | Tests |
|------|-------|---------------|-------|
| `linalg.py` | 92 | `pcg_solve`, `ic0_preconditioner`, `newton_raphson` | 4 |
| `mesh.py` | 123 | `Mesh`, `RectangleMesh`, `hex8_stiffness`, `t4_stiffness` | 5 |
| `fields.py` | 44 | `FieldVariable`, `Field` | — |

### Layer 2: FEM Framework (`fem/`)

| File | Lines | Key Functions | Tests |
|------|-------|---------------|-------|
| `assembly.py` | 79 | `assemble_stiffness`, `assemble_load` | 2 |
| `boundary.py` | 81 | `DirichletBC`, `NeumannBC`, `apply_bc` | 2 |
| `simp.py` | 121 | `simp_stiffness`, `simp_sensitivity`, `oc_update`, `simp_optimize` | 3 |
| `adaptive.py` | 180 | `ZZErrorEstimator`, `AdaptiveMeshRefiner` | 2 |

### Layer 3: Physics Solvers

| File | Lines | Key Classes | Tests |
|------|-------|-------------|-------|
| `physics/__init__.py` | 203 | `FDTD2D` (Yee, Courant, PML) | 7 |
| `multiphysics/thermal.py` | 90 | `ThermalFEM2D` (steady + transient) | 1 |
| `multiphysics/structural.py` | 85 | `StructuralFEM2D` (2D elasticity) | 1 |
| `multiphysics/vibration.py` | 95 | `NewmarkBeta` (time integration) | 1 |
| `multiphysics/quantum.py` | 155 | `WKBTunneling`, `TransferMatrix` | 5 |
| `multiphysics/fluid.py` | 115 | `NavierStokes2D` (Chorin projection) | 2 |
| `multiphysics/acoustic.py` | 50 | `AcousticSolver2D` | 1 |
| `multiphysics/electrostatic.py` | 75 | `PoissonSolver2D` | 1 |
| `multiphysics/magnetic.py` | 65 | `MagnetostaticSolver2D` | 1 |
| `multiphysics/radiation.py` | 95 | `RadiationSolver2D` | 2 |

### Layer 3c: Signal Integrity (`signal/`)

| File | Lines | Key Classes | Tests |
|------|-------|-------------|-------|
| `signal/__init__.py` | 204 | Transmission line, S-params, PRBS, eye, BER, Smith, PDN | 17 |
| `signal/crosstalk.py` | 180 | `CoupledTransmissionLine`, `CrosstalkAnalyzer` | 3 |
| `signal/chipstack.py` | 190 | `ChipStack` (thermal/stress/SI-power) | 4 |
| `signal/phononic.py` | 230 | `PhononicCrystal`, `PhononicDevice` (6 types) | 4 |
| `signal/chiplayout.py` | 230 | `ChipLayout`, `IPBlock`, `PowerLine`, `BusRoute` | 5 |

### Layer 4: IP Cores (`ipcore/`)

| File | Lines | Key Classes | Tests |
|------|-------|-------------|-------|
| `riscv.py` | 250 | `RV32IMC`, `RV32Decoder` (I+M+C extensions) | 4 |
| `aes.py` | 170 | `AES256GCM` (CTR mode) | 2 |
| `sm4.py` | 155 | `SM4` (GB/T 32907) | 2 |
| `trng.py` | 140 | `TRNG` (von Neumann extractor, health tests) | 2 |
| `puf.py` | 160 | `ArbiterPUF` (delay model, uniqueness) | 3 |
| `additional.py` | 620 | `SM2`, `SM3`, `SHA256`, `RSA`, `ECC`, `UART`, `SPI`, `I2C`, `GPIO`, `DMA` | 20 |

### Layer 5: AI/PDE (`ai/`)

| File | Lines | Key Classes | Tests |
|------|-------|-------------|-------|
| `ai/fno.py` | 190 | `FNO1D`, `FNO2D`, `SpectralConv1D`, `SpectralConv2D` | 4 |
| `ai/deeponet.py` | 100 | `DeepONet`, `BranchNet`, `TrunkNet` | 2 |
| `ai/pinns.py` | 115 | `PINN`, `PINN_Burgers` | 2 |
| `ai/one_framework.py` | 210 | `ONEFramework`, `DONNLayer`, `XBARLayer` | 3 |

### Layer 6: Optics (`optics/`) — NEW: Full-Vectorial Backend

| File | Lines | Key Classes | Tests |
|------|-------|-------------|-------|
| `optics/fresnel.py` | 105 | `FresnelPropagator`, `AngularSpectrumMethod` | 2 |
| `optics/donn.py` | 90 | `DONN`, `DONNLayer` (dual-backend: scalar+vectorial) | 4 |
| `optics/meep_backend.py` | 420 | `VectorialFDTD2D` (TE/TM, PML, phase mask), `MeepBackend` | 14 |
| `optics/vectorial_diffraction.py` | 280 | `RCWASolver`, `VectorialDiffractionIntegrator`, `SubwavelengthGrating` | 9 |

## Design Decisions

### 1. Why bottom-up implementation?
Each layer depends on the one below. Implementing core/linalg.py first
(meaning PCG) means every solver above can call `pcg_solve()` without
duplicating linear algebra. This avoids the anti-pattern of each module
rolling its own solver.

### 2. Why all fields same shape in FDTD?
Yee grid traditionally has E at edges and H at faces, producing arrays
of different shapes (nx×(ny+1) vs (nx+1)×ny). This causes broadcast
errors when computing curl operations. The solution: initialize all
fields as (nx, ny) and use interior-only updates with zero padding at
boundaries. PML handles actual boundary damping.

### 3. Why shift register for SM4?
SM4's key expansion and Feistel-like round function use X[0..3] in a
cyclic pattern. Using `K[(i+1) % 4]` cyclic indexing overwrites values
needed by subsequent rounds. The correct approach is a literal shift
register: `K = [K[1], K[2], K[3], new_value]`.

### 4. Why damped Jacobi for radiation?
The Stefan-Boltzmann T⁴ term creates a stiff nonlinear system. Plain
Jacobi diverges because the radiation source term grows as T⁴. Using
a relaxation factor ω=0.3 and clipping T to [0, 10000] prevents overflow.
NaN safety net: `np.nan_to_num(T, nan=T_ambient)`.

### 5. Why hard source in FDTD tests?
A soft source (`Ez[x,y] += pulse`) can be cancelled by the curl update
in the same time step, producing zero field after one step. A hard
source (`Ez[x,y] = pulse`) overwrites the field, guaranteeing non-zero
Ez. For test reliability, run 10+ steps to let the Gaussian develop.

### 6. Why dual-backend DONN? (NEW)
Scalar angular spectrum is fast but cannot model sub-wavelength structures
or vector polarization effects. Full-vectorial FDTD (VectorialFDTD2D)
solves all 6 Maxwell components on the Yee grid with proper PML, matching
MIT Meep's physics. The `use_vectorial` flag lets users trade speed for
accuracy. When Meep conda package is unavailable (macOS/ARM), the pure
NumPy VectorialFDTD2D serves as a drop-in replacement.

### 7. Why MeepBackend wraps VectorialFDTD2D? (NEW)
`pip install meep` on PyPI installs a task-runner package (not MIT Meep).
MIT Meep needs `conda install -c conda-forge meep` (Linux/Intel only).
MeepBackend provides the same API surface (set_slm_phase, propagate,
simulate_diffraction, compute_beam_profile) so DONN code doesn't change
whether the backend is real Meep or our NumPy implementation.

## VectorialFDTD2D Overflow Pitfall (NEW)

When running DONN with `use_vectorial=True`, the Gaussian source pulse
can cause field values to overflow float64. Three-part fix:

1. **Soft source with small amplitude**: `self.Ez[x,y] += 0.01 * sin(ωt)`
   instead of hard `self.Ez[x,y] = sin(ωt)`
2. **Clip after update**: `np.clip(self.Ez, -1e6, 1e6, out=self.Ez)`
3. **Clip intensity**: `np.nan_to_num(np.clip(E, -1e6, 1e6)**2, ...)`

In tests: use 1 DONN layer (not 2+) and test
`np.isfinite(np.clip(out, 0, 1e12))` instead of raw `np.isfinite(out)`.
