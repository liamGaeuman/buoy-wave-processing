%% Simulation Data
simu = simulationClass();
simu.simMechanicsFile = 'Buoy.slx';

simu.startTime = 0;
simu.rampTime = 20;
simu.endTime = 100;
simu.dt = 0.001;

%% Wave Information
waves = waveClass('regular');
waves.height = 0.4;
waves.period = 8.0;

%% Body Data
body(1) = bodyClass('hydroData/Buoy.h5');
body(1).geometryFile = 'geometry/Buoy-water-line.STL';

body(1).mass = 'equilibrium';
body(1).inertia = [0.254 0.254 0.335];
body(1).centerGravity = [0 0 0.097];

%% Constraint Data
constraint(1) = constraintClass('Heave_Joint');
constraint(1).location = [0 0 0.097];