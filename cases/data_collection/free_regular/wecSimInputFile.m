%% Simulation Data
simu = simulationClass();
simu.simMechanicsFile = 'Buoy.slx';

simu.startTime = 0;
simu.rampTime  = 100;

simu.dt    = 0.0125;   % 160 simulation steps per 2 s wave
simu.dtOut = 0.0625;   % 16 Hz output

% 20 min of data after 100 s ramp-up
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
% Free 6-DOF buoy
constraint(1) = constraintClass('Floating_Joint');
constraint(1).location = [0 0 0];   % w.r.t. h5 waterline origin