% 1. Read Capytaine NetCDF file
hydro = struct();
hydro = readCAPYTAINE(hydro, 'Buoy.nc');

% 2. Patch hydrostatics not transferred correctly from Capytaine .nc
hydro.cg = [0; 0; 0.097];

hydro.cb = [
    5.46625411e-06;
    3.80584400e-09;
   -3.54452264e-02
];

hydro.Vo = 0.011613026209917577;

% Optional verification
disp('Patched hydrostatics:')
disp('cg =')
disp(hydro.cg)
disp('cb =')
disp(hydro.cb)
disp('Vo =')
disp(hydro.Vo)

% 3. Calculate Impulse Response Functions (IRF)
hydro = radiationIRF(hydro, 60, [], [], [], []);
hydro = excitationIRF(hydro, 60, [], [], [], []);

% 4. Write data to a WEC-Sim formatted .h5 file
writeBEMIOH5(hydro);

% 5. Plot the hydrodynamic data to verify it looks correct
plotBEMIO(hydro);