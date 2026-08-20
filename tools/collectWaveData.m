%% collectWaveData.m
% Runs all five wave conditions for the current WEC-Sim case and
% saves the post-ramp Response Class data to run-specific CSV files.

clearvars;
clc;


%% Wave Conditions

waveHeights = [0.15, 0.65, 1.20, 1.85, 2.50];
wavePeriods = [2.00, 3.00, 4.00, 5.00, 6.00];


%% Determine Simulation Case From Current Folder

[~, caseFolder] = fileparts(pwd);
folderLower = lower(caseFolder);

if contains(folderLower, 'constraint') || contains(folderLower, 'contstraint')
    caseTag = 'heave_regular';

elseif contains(folderLower, 'jonswap')
    caseTag = 'free_jonswap';

elseif contains(folderLower, 'freebuoy')
    caseTag = 'free_regular';

else
    error(['Could not determine simulation case from folder name: ', ...
           caseFolder]);
end

fprintf('\nSimulation case: %s\n', caseTag);
fprintf('Running %d wave conditions.\n\n', numel(waveHeights));


%% Data Collection Settings

rampTime = 100;       % discard first 100 s
endTime  = 1300;      % total simulation time
fs       = 16;        % output sampling rate [Hz]

expectedSamples = (endTime - rampTime) * fs;   % 19,200 samples


%% Run All Wave Conditions

for k = 1:numel(waveHeights)

    % These variables are read by wecSimInputFile.m
    waveHeight = waveHeights(k);
    wavePeriod = wavePeriods(k);

    fprintf('============================================================\n');
    fprintf('Run %d of %d\n', k, numel(waveHeights));
    fprintf('H = %.2f m, T = %.2f s\n', waveHeight, wavePeriod);
    fprintf('============================================================\n\n');

    % Remove previous WEC-Sim output before starting next run
    if exist('output', 'var')
        clear output;
    end

    %% Run WEC-Sim
    wecSim;


    %% Pull Response Class Outputs

    waveOut       = output.wave;
    bodyOut       = output.bodies(1);
    constraintOut = output.constraints(1);


    %% Remove Ramp-Up Data
    %
    % Keep:
    %       100 <= t < 1300
    %
    % This gives exactly:
    %       1200 s * 16 Hz = 19,200 samples

    bodyTime = bodyOut.time(:);

    keep = bodyTime >= rampTime & bodyTime < endTime;

    simTime = bodyTime(keep);

    if sum(keep) ~= expectedSamples
        error(['Expected %d post-ramp samples, but found %d. ', ...
               'Check dtOut and simulation timing.'], ...
               expectedSamples, sum(keep));
    end

    % Reset retained time so each CSV begins at t = 0
    time_s = simTime - rampTime;


    %% Wave Class Outputs

    waveElevation = alignToTime( ...
        waveOut.time, ...
        waveOut.elevation, ...
        simTime);


    %% Start CSV Data Matrix

    data = [
        time_s, ...
        waveElevation
    ];

    names = {
        'time_s', ...
        'wave_elevation_m'
    };


    %% Body Class: Position

    data = [data, bodyOut.position(keep,:)];

    names = [names, {
        'body_position_x_m', ...
        'body_position_y_m', ...
        'body_position_z_m', ...
        'body_roll_rad', ...
        'body_pitch_rad', ...
        'body_yaw_rad'
    }];


    %% Body Class: Velocity

    data = [data, bodyOut.velocity(keep,:)];

    names = [names, {
        'body_velocity_x_m_s', ...
        'body_velocity_y_m_s', ...
        'body_velocity_z_m_s', ...
        'body_omega_x_rad_s', ...
        'body_omega_y_rad_s', ...
        'body_omega_z_rad_s'
    }];


    %% Body Class: Acceleration

    data = [data, bodyOut.acceleration(keep,:)];

    names = [names, {
        'body_acceleration_x_m_s2', ...
        'body_acceleration_y_m_s2', ...
        'body_acceleration_z_m_s2', ...
        'body_alpha_x_rad_s2', ...
        'body_alpha_y_rad_s2', ...
        'body_alpha_z_rad_s2'
    }];


    %% Body Class: Hydrodynamic Forces and Moments

    forceFields = {
        'forceTotal'
        'forceExcitation'
        'forceRadiationDamping'
        'forceAddedMass'
        'forceRestoring'
        'forceMorisonAndViscous'
        'forceLinearDamping'
    };

    for f = 1:numel(forceFields)

        fieldName = forceFields{f};
        forceData = bodyOut.(fieldName)(keep,:);

        data = [data, forceData];

        names = [names, {
            ['body_' fieldName '_x_N'], ...
            ['body_' fieldName '_y_N'], ...
            ['body_' fieldName '_z_N'], ...
            ['body_' fieldName '_Mx_Nm'], ...
            ['body_' fieldName '_My_Nm'], ...
            ['body_' fieldName '_Mz_Nm']
        }];
    end


    %% Constraint Class Outputs
    %
    % Align constraint output to the same 16 Hz time vector used
    % for the body output.

    constraintPosition = alignToTime( ...
        constraintOut.time, ...
        constraintOut.position, ...
        simTime);

    constraintVelocity = alignToTime( ...
        constraintOut.time, ...
        constraintOut.velocity, ...
        simTime);

    constraintAcceleration = alignToTime( ...
        constraintOut.time, ...
        constraintOut.acceleration, ...
        simTime);

    constraintForce = alignToTime( ...
        constraintOut.time, ...
        constraintOut.forceConstraint, ...
        simTime);


    % Constraint position
    data = [data, constraintPosition];

    names = [names, {
        'constraint_position_x_m', ...
        'constraint_position_y_m', ...
        'constraint_position_z_m', ...
        'constraint_roll_rad', ...
        'constraint_pitch_rad', ...
        'constraint_yaw_rad'
    }];


    % Constraint velocity
    data = [data, constraintVelocity];

    names = [names, {
        'constraint_velocity_x_m_s', ...
        'constraint_velocity_y_m_s', ...
        'constraint_velocity_z_m_s', ...
        'constraint_omega_x_rad_s', ...
        'constraint_omega_y_rad_s', ...
        'constraint_omega_z_rad_s'
    }];


    % Constraint acceleration
    data = [data, constraintAcceleration];

    names = [names, {
        'constraint_acceleration_x_m_s2', ...
        'constraint_acceleration_y_m_s2', ...
        'constraint_acceleration_z_m_s2', ...
        'constraint_alpha_x_rad_s2', ...
        'constraint_alpha_y_rad_s2', ...
        'constraint_alpha_z_rad_s2'
    }];


    % Constraint forces / moments
    data = [data, constraintForce];

    names = [names, {
        'constraint_force_x_N', ...
        'constraint_force_y_N', ...
        'constraint_force_z_N', ...
        'constraint_moment_x_Nm', ...
        'constraint_moment_y_Nm', ...
        'constraint_moment_z_Nm'
    }];


    %% Create CSV Filename

    % Examples:
    % H = 0.15 --> H015
    % H = 1.20 --> H120
    % T = 2.00 --> T200
    % T = 4.00 --> T400

    heightCode = sprintf('%03d', round(waveHeight * 100));
    periodCode = sprintf('%03d', round(wavePeriod * 100));

    fileName = sprintf( ...
        '%s_H%s_T%s.csv', ...
        caseTag, ...
        heightCode, ...
        periodCode);


    %% Write CSV

    csvTable = array2table(data, 'VariableNames', names);

    writetable(csvTable, fileName);

    fprintf('\nSaved: %s\n', fileName);
    fprintf('Samples: %d\n', height(csvTable));
    fprintf('Duration: %.1f s\n\n', height(csvTable) / fs);

end


fprintf('============================================================\n');
fprintf('All runs complete.\n');
fprintf('============================================================\n');


%% ------------------------------------------------------------------------
% Local Function
% -------------------------------------------------------------------------
%
% Aligns another Response Class time series to the body time vector.
% Normally these should already have the same 16 Hz timestamps, but this
% makes the CSV construction robust if there are small timing differences.

function alignedData = alignToTime(sourceTime, sourceData, targetTime)

    sourceTime = sourceTime(:);
    targetTime = targetTime(:);

    if numel(sourceTime) == numel(targetTime) && ...
       max(abs(sourceTime - targetTime)) < 1e-9

        alignedData = sourceData;

    else

        alignedData = interp1( ...
            sourceTime, ...
            sourceData, ...
            targetTime, ...
            'linear');

    end

end