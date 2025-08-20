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