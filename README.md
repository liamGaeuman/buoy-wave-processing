# Buoy Wave Processing

Tools for simulating buoy motion and processing buoy sensor data for wave estimation.

The current simulation pipeline uses Capytaine to compute hydrodynamic coefficients, BEMIO to convert those coefficients to WEC-Sim format, and WEC-Sim to simulate buoy motion in waves.

## Repository Structure

```text
buoy-wave-processing/
├── README.md
├── models/
│   ├── geometry/
│   └── simulink/
├── hydrodynamics/
│   ├── capytaine/
│   └── bemio/
├── hydroData/
├── cases/
│   ├── heave_regular/
│   ├── free_regular/
│   └── free_jonswap/
├── analysis/
├── tools/
└── data/
```

Case folders should contain only the files that differ between simulations when possible. Shared geometry, Simulink models, and hydrodynamic data should not be duplicated between cases.

## Simulation

### Simulation Pipeline

```text
STL geometry
    ↓
Capytaine
    ↓
Buoy.nc
    ↓
BEMIO
    ↓
Buoy.h5
    ↓
WEC-Sim / Simulink
    ↓
Buoy simulation
```

### Capytaine

See the [Capytaine documentation](https://capytaine.org/stable/user_manual/index.html) for installation and general usage.

The Capytaine calculation uses:

```text
Buoy-water-line.STL
```

with the coordinate convention:

```text
waterline: z = 0
CoM:       z = +0.097 m
```

This geometry is used because the Capytaine hydrodynamic model is defined relative to the mean free surface at `z = 0`.

The Capytaine notebook computes the buoy hydrodynamic coefficients and exports them to:

```text
Buoy.nc
```

### BEMIO / Hydrodynamic Data Transfer

BEMIO converts the Capytaine NetCDF output to the HDF5 format used by WEC-Sim:

```text
Buoy.nc → BEMIO → Buoy.h5
```

In the current workflow, BEMIO does not recover the center of gravity (`cg`), center of buoyancy (`cb`), or displaced volume (`Vo`) from the Capytaine NetCDF file. These values are therefore inserted into the BEMIO structure before writing `Buoy.h5`:

```matlab
hydro = readCAPYTAINE(hydro, 'Buoy.nc');

hydro.cg = [0; 0; 0.097];

hydro.cb = [
    5.46625411e-06;
    3.80584400e-09;
   -3.54452264e-02
];

hydro.Vo = 0.011613026209917577;
```

After the radiation and excitation impulse-response functions are generated, the WEC-Sim hydrodynamic file is written with:

```matlab
writeBEMIOH5(hydro);
```

The resulting `Buoy.h5` contains the hydrodynamic coefficients and corrected body properties needed by WEC-Sim.

### WEC-Sim

See the [WEC-Sim documentation](https://wec-sim.github.io/WEC-Sim/dev/user/index.html) for installation and instructions for setting up a WEC-Sim case.

Each case uses:

- a WEC-Sim input file defining the simulation and wave conditions;
- a Simulink model defining the allowed body motion;
- `Buoy.h5` for hydrodynamic data; and
- `Buoy-CoM-line.STL` for the WEC-Sim body geometry.

#### Simulink Models

Two Simulink configurations are used.

**Heave-only**

The buoy is constrained to vertical translation. The other degrees of freedom are disabled.

**Free 6-DOF**

The buoy uses a floating 6-DOF constraint and is free to translate and rotate.

Different wave conditions, such as regular waves and JONSWAP irregular waves, can use the same free-body Simulink model. These differences belong in the WEC-Sim input file rather than separate copies of the Simulink model.

#### Geometry and Coordinate Conventions

Capytaine and WEC-Sim use different STL origins for this project.

| File | Used by | Origin | Waterline |
|---|---|---|---|
| `Buoy-water-line.STL` | Capytaine | Waterline | `z = 0` |
| `Buoy-CoM-line.STL` | WEC-Sim | Center of mass | `z = -0.097 m` |

For the WEC-Sim STL:

```text
CoM:       z = 0
waterline: z = -0.097 m
```

The body center of gravity stored in `Buoy.h5` is:

```text
[0, 0, 0.097] m
```

WEC-Sim therefore places the STL waterline at the global undisturbed free surface:

```text
+0.097 - 0.097 = 0 m
```

The two STL files represent the same physical buoy but use different coordinate origins. They should not be interchanged.

#### Body Inertia

The buoy mass moments of inertia come from the CAD model and are specified in the WEC-Sim input file:

```matlab
body(1).inertia = [0.254 0.254 0.335];   % kg*m^2
```

The body center of gravity does not need to be manually specified in the WEC-Sim input file because it is stored in `Buoy.h5`.

#### Running a Case

1. Install and initialize WEC-Sim.
2. Select the appropriate WEC-Sim input file.
3. Use the heave-only or free-6DOF Simulink model as required.
4. Use `Buoy.h5` and `Buoy-CoM-line.STL`.
5. Run:

```matlab
wecSim
```

#### Visualization

The simulation can be viewed directly in Simscape Multibody Explorer. Because the buoy is small relative to the default environment, it may initially appear very small.

Use the **Zoom** or **Zoom to Region** tools in Multibody Explorer to focus on the buoy. With a mouse, zooming can also be performed by holding `Ctrl`, holding the scroll wheel, and moving the mouse up or down. Press `Space` to return to a fit-to-view camera position.

WEC-Sim can also generate an animation showing the buoy together with the simulated wave surface.

After `wecSim` finishes, run:

```matlab
output.saveViz(simu, body, waves, ...
    'timesPerFrame', 100, ...
    'axisLimits', [-6 6 -3 3 -1 1]);
```

`axisLimits` controls the displayed region in the format:

```text
[xmin xmax ymin ymax zmin zmax]
```

For a small buoy, relatively tight axis limits are useful so that the body remains visible.

`timesPerFrame` controls how many simulation time steps are skipped between animation frames. Increasing it makes visualization generation faster but reduces the temporal resolution of the animation.

The same command works with regular and irregular wave cases, including JONSWAP waves.

## Simulation Data Export

<!-- To be added. -->

## Data Porting

<!-- To be added as the data-transfer workflow is developed. -->

## Data Processing and Analysis

<!-- To be added as the processing pipeline is developed. -->

## References

- [WEC-Sim Documentation](https://wec-sim.github.io/WEC-Sim/dev/user/index.html)
- [Capytaine Documentation](https://capytaine.org/stable/user_manual/index.html)
- [BEMIO Repository](https://github.com/WEC-Sim/bemio)