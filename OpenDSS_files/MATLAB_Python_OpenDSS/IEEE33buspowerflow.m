% Number of iterations to measure runtime
runs = 10;

% Array to store runtimes for each iteration
runtimes = zeros(runs, 1);

for run = 1:runs
    % Start timer
    tic;
    
    % Create an OpenDSS COM interface
    DSSObj = actxserver('OpenDSSEngine.DSS');
    
    % Start the DSS
    if ~DSSObj.Start(0)
        error('OpenDSS failed to start.');
    end
    
    % Get interfaces
    DSSText = DSSObj.Text;        % Interface for executing DSS commands
    DSSCircuit = DSSObj.ActiveCircuit;  % Interface for the active circuit
    DSSSolution = DSSCircuit.Solution; % Interface for the solution

    % Load and solve the DSS script
    DSSText.Command = 'Clear';                  % Clear existing circuit
    DSSText.Command = 'Compile IEEE33buspowerflow.dss';  % Compile your DSS script
    DSSSolution.Solve;                          % Solve the power flow
        
    % Get the list of all buses
    allBusNames = DSSCircuit.AllBusNames;
    numBuses = DSSCircuit.NumBuses;

    % Initialize arrays to store results
    voltageMagnitudes = zeros(numBuses, 1); % Voltage magnitudes (pu)
    voltageAngles = zeros(numBuses, 1);     % Voltage angles (degrees)

    % Loop through each bus and retrieve voltage profiles
    for i = 1:numBuses
        % Set the active bus
        DSSCircuit.SetActiveBus(allBusNames{i});
        DSSBus = DSSCircuit.ActiveBus;

        % Retrieve voltage magnitude (in per unit) and angle (in degrees)
        puVoltages = DSSBus.puVmagAngle;  % Returns [magnitude, angle]
        voltageMagnitudes(i) = puVoltages(1);  % Voltage magnitude (pu)
        voltageAngles(i) = puVoltages(2);      % Voltage angle (degrees)
    end
    
    % Stop timer and store runtime
    runtimes(run) = toc;
end

% Calculate the average runtime
averageRuntime = mean(runtimes);

% Display results
disp(['Average runtime over ', num2str(runs), ' run: ', num2str(averageRuntime), ' seconds']);

% Get the total number of iterations
numIterations = DSSSolution.Totaliterations;  % Total number of iterations

% Get total active and reactive power in the system
totalActivePower = (-1)* DSSCircuit.TotalPower(1)/1000;  % Active power in MW (NB: The (-1) is added since it is the load. So that the result will return a positive value.
totalReactivePower = (-1) * DSSCircuit.TotalPower(2)/1000; % Reactive power in MVAR

% Get total active and reactive losses in the system
totalActiveLosses = DSSCircuit.Losses(1)/1000;  % Active power losses in MW
totalReactiveLosses = DSSCircuit.Losses(2)/1000; % Reactive power losses in MVAR

% Get the maximum and minimum per-unit voltage
maxVoltage = max(voltageMagnitudes);  % Max voltage (per unit)
minVoltage = min(voltageMagnitudes);  % Min voltage (per unit)

% Display the results
fprintf('Total Iterations: %d\n', numIterations);
fprintf('Max pu. voltage: %.5f\n', maxVoltage);
fprintf('Min pu. voltage: %.5f\n', minVoltage);
fprintf('Total Active Power: %.5f MW\n', totalActivePower);
fprintf('Total Reactive Power: %.5f Mvar\n', totalReactivePower);
fprintf('Total Active Losses: %.5f kW\n', totalActiveLosses);
fprintf('Total Reactive Losses: %.5f kvar\n', totalReactiveLosses);


% Calculate and display active power losses percentage
activeLossPercentage = ((totalActiveLosses/1000) / totalActivePower) * 100;
fprintf('Active Loss Percentage: %.2f %%\n', activeLossPercentage);

%{
% Display results
disp('Voltage Magnitudes (pu):');
disp(voltageMagnitudes);

disp('Voltage Angles (degrees):');
disp(voltageAngles);


% Plot voltage magnitude and angle profiles
figure;
subplot(1,2,1);
plot(1:numBuses, voltageMagnitudes, 'LineWidth', 1.5);
%grid on;
title('Voltage Magnitude Profile');
xlabel('Bus Number');
ylabel('Voltage (pu)');

subplot(1,2,2);
plot(1:numBuses, voltageAngles, 'LineWidth', 1.5);
%grid on;
title('Voltage Angle Profile');
xlabel('Bus Number');
ylabel('Angle (degrees)');
%}
% Given data
computation_time = [0.032985, 0.012825, 0.01824, 0.013764];
max_voltage_errors = [0.700637, 0.006641, 0.000218, 0.000007];

% Calculate cumulative computation time
cumulative_time = cumsum(computation_time);

% Plot the graph
figure;
plot(cumulative_time, max_voltage_errors, '-o', 'LineWidth', 2, 'MarkerSize', 8);
grid on;

% Add labels and title
xlabel('Cumulative Computation Time (seconds)', 'FontSize', 12);
ylabel('Maximum Voltage Error', 'FontSize', 12);
title('Computation Time vs. Maximum Voltage Error', 'FontSize', 14);

% Customize axis
set(gca, 'FontSize', 10);
