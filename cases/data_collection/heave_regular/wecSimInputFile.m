%% Simulation Data
simu = simulationClass();
simu.simMechanicsFile = 'Buoy.slx';

simu.startTime = 0;
simu.rampTime  = 100;

simu.dt    = 0.0125;
simu.dtOut = 1/16;

simu.endTime = 1300;

%% Wave Information
waves = waveClass('regular');

% Set by outer data-collection script
waves.height = waveHeight; 
waves.period = wavePeriod;

%% Body Data
body(1) = bodyClass('hydroData/Buoy.h5');
body(1).geometryFile = 'geometry/Buoy-CoM-line.STL';

body(1).mass = 'equilibrium';
body(1).inertia = [0.254 0.254 0.335];

%% Constraint Data
constraint(1) = constraintClass('Heave_Joint');
constraint(1).location = [0 0 0];