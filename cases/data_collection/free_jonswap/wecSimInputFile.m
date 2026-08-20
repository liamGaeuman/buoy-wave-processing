%% Simulation Data
simu = simulationClass();
simu.simMechanicsFile = 'Buoy.slx';

simu.startTime = 0;
simu.rampTime  = 100;

simu.dt    = 0.0125;
simu.dtOut = 1/16;

simu.endTime = 1300;   % 100 s ramp + 20 min data


%% Wave Information
waves = waveClass('irregular');

% Set by outer data-collection script
waves.height = waveHeight;   % significant wave height Hs
waves.period = wavePeriod;   % peak period Tp

waves.spectrumType = 'JS';


%% Body Data
body(1) = bodyClass('hydroData/Buoy.h5');
body(1).geometryFile = 'geometry/Buoy-CoM-line.STL';

body(1).mass = 'equilibrium';
body(1).inertia = [0.254 0.254 0.335];


%% Constraint Data
% Free 6-DOF buoy
constraint(1) = constraintClass('Floating_Joint');
constraint(1).location = [0 0 0];