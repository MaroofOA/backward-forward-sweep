% Define the function for the backward_forward method for distribution network analysis.
function [v, iteration] = bfs_method(load_data, line_data, slack_bus_voltage, tolerance, max_iter, runs, v_base, s_base)
    % Arguments include the constant slack bus voltage, convergence value, and max. iterations,
    % all of which can be changed when the function is called.
    
    prompt = {'Ensure the argument data i.e, load and line data are in this format:'
                   'load data: column1 - bus index, column2 - real power (P), and column3 - reactive power (Q)'
                   'line data: column1 - sending bus index, column2 - receiving bus index, column3 - resistance (R), and reactance (X)'
                   'Line data can also have a 5th column if we are dealing with two different voltage levels. In such case, the 5th colum will be the voltage level/base'
                   '\n'
                   'The default value are slack_bus_voltage = 1.5, tolerance = 1e-6, and max_iter = 100'
                   'If you decide to change any of the constant argument value, such as slack_bus_voltage, tolerance, or max_iter, just pass the new value in their respective position'
                   'If you will jump any of the order, kindly put the constant value of the one you are jumping in its position and input the new value of the argument you are changing'
                   'For example: [v, iteration] = bfs_method(load_data, line_data, 1.5, 1e-4), this is because, I want to keep the slack bus the same but want to change the tolerance'
                   'I did not put the value of max_iter because, it is the last one and I want to keep it the same.'
                   };
    disp(prompt);
    user_input = input('Press Enter to continue or type ''quit'' to exit; ', 's');

     % Check if the user wants to quit
    if strcmp(user_input, 'quit')% strcmp is the MATLAB function for comparing two string  first to last
        disp('Exiting the function as per user request probably because the data does not conform with the requirement');
        iteration = []; % Return an empty array
        v = [];
        return;
    end 
    
    if nargin < 3, slack_bus_voltage = 1; end
    if nargin < 4, tolerance = 1e-6; end
    if nargin < 5, max_iter = 100; end
    if nargin < 6, runs = 10; end
    if nargin < 7, v_base = 12.66; end
    if nargin < 8, s_base = 100; end
    
    % System base values
    % Managing the bases of different voltage levels between MV and LV
    if size(line_data, 2) >= 5
        V_base = line_data(:,5);  % per-line voltage base in kV
    else
        V_base = v_base * ones(size(line_data, 1), 1);  % default voltage base
    end
    
    S_base = s_base;  % GLOBAL S_base (in MVA) for the entire system
    Z_base = (V_base.^2) ./ S_base;  % per-line Z_base, consistent S_base

    num_buses = size(load_data, 1); % Number of buses
    P_load = load_data(:, 2) / 100000; % Real power in p.u. by 100MVA
    Q_load = load_data(:, 3) / 100000; % Reactive power in p.u. by 100MVA

    % Preallocate arrays to improve performance
    max_voltage_errors = zeros(1, max_iter);
    % cumulative_iter_times = zeros(1, max_iter);
    computation_times = zeros(1, runs);
    Zbus_time = zeros(1, runs);
    iter_time = zeros(runs, max_iter);

    for run = 1:runs
        % Initialize bus voltages
        v = ones(num_buses, 1) + 1j * zeros(num_buses, 1); % Let all the initial voltage for all the buses be 1.0 p.u.
        v(1) = slack_bus_voltage; % Set the slack bus voltage

        % Create load vectors
        S_load = P_load + 1j * Q_load; % Complex power (S = P + jQ)
        
        % Measure the computational time to compute Ybus
        Zbus_start_time = tic;
        % Create line impedance matrix
        Z_line = zeros(num_buses, num_buses)+ 1j * zeros(num_buses, num_buses); % Initialize the line impedance matrix with zeros.
        for i = 1:size(line_data, 1) % Iterate over each line in the line_data.
            from_bus = line_data(i, 1); % Get the starting bus index of the line.
            to_bus = line_data(i, 2); % Get the ending bus index of the line.
            R = line_data(i, 3); % Extract the resistance of the line. Already in p.u.
            X = line_data(i, 4); % Extract the reactance of the line. Already in p.u.
            Z_line(from_bus, to_bus) = (R + 1j * X)/Z_base(i); % Set the impedance (R + jX) in the impedance matrix.
            Z_line(to_bus, from_bus) = (R + 1j * X)/Z_base(i); % Assuming the line impedance is symmetrical and set opposite entry.
        end
        
        Zbus_time(run) = toc(Zbus_start_time);

        % Measure the computational time
        start_time = tic;
        % Backward-Forward Sweep method
        for iteration = 1:max_iter % Iterate up to max_iter times to perform the BFS algorithm.
            % Start timing for the iteration
            iter_start_time = tic;

            V_old = v; % Copy the current bus voltages to V_old for convergence checking.

            % Backward Sweep
            I_load = zeros(num_buses, 1) + 1j * zeros(num_buses, 1); % Initialize the load currents with zeros.
            I_branch = zeros(num_buses, num_buses) + 1j * zeros(num_buses, num_buses); % Initialize the branch currents with zeros.

            % Calculate load currents
            for i = 1:num_buses % Iterate over each of the buses
                I_load(i) = conj(S_load(i) / v(i)); % Calculate load current at bus i
            end

            % Calculate branch currents explicitly
            for i = num_buses:-1:2 % Iterate backward from the last bus to the first bus
                for j = 1:num_buses % Iterate over all buses to sum the downstream currents.
                    if Z_line(j, i) ~= 0 % Check if there's an impedance (i.e., connection)
                        I_branch(j, i) = I_load(i) + sum(I_branch(i, :)); % I_ij = I_j + sum of all currents leaving j
                    end
                end
            end

            % Forward Sweep
            v(1) = V_old(1); % Voltage at the slack bus remains the same

            % Iterate over each bus to update voltages
            for i = 2:num_buses % Start from bus 2 (excluding slack bus)
                for j = 1:i-1 % Iterate over all predecessor buses to find the connection
                    if Z_line(j, i) ~= 0 % There is an impedance between buses j and i
                        % Calculate the voltage for bus i based on bus j
                        current = I_branch(j, i); % Current in the branch from j to i
                        impedance = Z_line(j, i); % Impedance of the branch from j to i
                        v(i) = v(j) - impedance * current; % Update the voltage of bus i
                        % fprintf('The voltage of bus %d after %d iteration = %.4f\n', i, iteration, v(i));
                        % Break after the first update to ensure each bus is updated only once
                        break;
                    end
                end
            end

            % End the iteration time
            iter_time(run, iteration) = toc(iter_start_time);

            % Check for convergence
            max_diff = max(abs(v - V_old));

            % Store max voltage difference and cumulative iteration time
            max_voltage_errors(iteration) = max_diff;  % Assign value directly

            % if iteration == 1
            %    cumulative_iter_times(iteration) = iter_time;
            % else
            %    cumulative_iter_times(iteration) = cumulative_iter_times(iteration - 1) + iter_time;
            % end

            % Print max voltage difference at an iteration and its respective
            % computation time till that iteration.
            % fprintf('Iteration %d: max voltage difference = %.10f\n', iteration, max_diff);
            % fprintf('Time taken till %d iteration: %.4f seconds\n', iteration, iter_time);
            
            if max_diff <= tolerance % Check if the maximum voltage difference between iterations is less than the tolerance.
                break; % Break the loop if convergence is achieved.
            end
        end

        % Store total computation time for the current run
        computation_times(run) = toc(start_time);
    
    end    
    
    % To handle only the iterations that were executed
    actual_iterations = iteration;  % Number of iterations performed until convergence
    max_voltage_errors = max_voltage_errors(1:actual_iterations);  % Adjust size of the errors array
    % cumulative_iter_times = cumulative_iter_times(1:actual_iterations);  % Adjust size of the cumulative times array
    
    % Prepare results and print them
    fprintf('Bus Voltages:\n'); % Print a header for the bus voltages.
    for i = 1:num_buses % Iterate over each bus voltage.
        magnitude = abs(v(i)); % Calculate the magnitude of the voltage.
        phase_angle = rad2deg(angle(v(i))); % Calculate the angle of the voltage in degrees.
        rectangular_form = sprintf('%.4f + %.4fj', real(v(i)), imag(v(i)));
        polar_form = sprintf('%.4f ∠ %.2f°', magnitude, phase_angle);
        fprintf('Bus %d: Rectangular form: %s p.u., Polar form: %s\n', i, rectangular_form, polar_form); % Print the voltage in both forms.
    end 
  
    % Compute system loss, substation power, and other results
    % Calculate system loss
    fprintf('\nSystem Losses:\n')
    [total_active_loss_pu, total_reactive_loss_pu] = calculate_system_loss(num_buses, line_data, v, Z_base);
    
    fprintf('\nConverged in %d iterations.\n', iteration); % Print the number of iterations it took to converge.
    
    total_active_loss = total_active_loss_pu * S_base;
    total_reactive_loss = total_reactive_loss_pu * S_base;
    fprintf('\nTotal active power loss = %.4f MW\n',total_active_loss);
    fprintf('Total reactive power loss = %.4f MVar\n', total_reactive_loss);
    
    % Calculate substation power
    substation_active_power = S_base * (sum(P_load) + total_active_loss_pu);
    substation_reactive_power = S_base * (sum(Q_load) + total_reactive_loss_pu);
    fprintf('Substation active power = %.4f MW\n', substation_active_power);
    fprintf('Substation reactive power = %.4f MVar\n', substation_reactive_power);
    
    % Find minimum and maximum voltages and their corresponding bus indices
    [min_voltage, min_index] = min(abs(v));
    [max_voltage, max_index] = max(abs(v));

    % Print the minimum and maximum voltages along with the bus indices
    fprintf('\nMinimum voltage = %.4f pu at bus %d\n', min_voltage, min_index);
    fprintf('Maximum voltage = %.4f pu at bus %d\n', max_voltage, max_index);

    % Calculate and print the computation time for Ybus
    fprintf('\nThe impedance matrix (zbus) was computed in %f secs\n', mean(Zbus_time));

    fprintf('\nAverage Computation time for each iterations after %d runs:\n', run)
    % compute average time for each iteration
    average_iter_time = mean(iter_time, 1);
    for i = 1:iteration
        fprintf('The average iteration time for iteration %d is %f seconds\n', ...
            i, average_iter_time(i));
    end
    
    % Get the cumulative sum of each iteration for plotting
    cumulative_iter_times = cumsum(average_iter_time(1:iteration));

    fprintf('\nCumulative sum of the average of each iteration per run:\n')
    disp(cumulative_iter_times)

    format longG
    fprintf('\nMaximum Voltage Error for each iteration:\n')
    disp(max_voltage_errors)

    % Store the formatted computation times as strings so as to return it
    % as a formated list of string in 4dp.
    formatted_times = arrayfun(@(x) sprintf('%.4f', x), computation_times, 'UniformOutput', false);
    
    % Print the formatted list of computation times
    fprintf('\nComputation times for each run: [%s]\n', strjoin(formatted_times, ', '));
    
    % Calculate and print the average computation time
    average_time = mean(computation_times);
    fprintf('Average computation time for the model after %d runs: %.4f seconds\n', runs, average_time);
       
    % Extract the magnitudes of the voltages
    voltage_magnitudes = abs(v);
    voltage_angles = angle(v);
    
    % disp(voltage_magnitudes);
    % disp(voltage_angles);
    
    % Create the graph using the provided line data to visualize the system
    % network
    G = digraph(line_data(:, 1), line_data(:, 2));
    % Plot the graph
    fig = figure;
    h = plot(G);
    % Customize the appearance
    h.NodeColor = 'r';  % Node color
    h.EdgeColor = 'b';  % Edge color
    h.ArrowSize = 10;   % Arrow size
    filename1 = sprintf('%d_bus_network.fig', num_buses);
    filename2 = sprintf('%d_bus_network.png', num_buses);
    savefig(fig, fullfile(pwd, 'Figures', filename1));
    exportgraphics(gcf, fullfile(pwd, 'Figures', filename2), 'Resolution', 300);
    close(fig);

    % Create a plot of bus voltages
    fig = figure;
    subplot(1, 2, 1); % 1 row, 2 columns, first subplot
    plot(1:length(voltage_magnitudes), voltage_magnitudes, '-', 'LineWidth', 2);
    set(gca, 'FontName', 'Palatino Linotype'); 
    xlabel('Bus Number', 'FontName', 'Palatino Linotype');
    ylabel('Voltage Magnitude (p.u.)', 'FontName', 'Palatino Linotype');
    title('Bus Voltage Profile', 'FontName', 'Palatino Linotype');
    % grid on;
    
    % Create a plot of bus voltages angle
    subplot(1, 2, 2); % 1 row, 2 columns, second subplot
    plot(1:length(voltage_angles), voltage_angles, '-', 'LineWidth', 2);
    set(gca, 'FontName', 'Palatino Linotype'); 
    xlabel('Bus Number', 'FontName', 'Palatino Linotype');
    ylabel('Voltage Angle (radian)', 'FontName', 'Palatino Linotype');
    title('Bus Voltage Angle', 'FontName', 'Palatino Linotype');
    % grid on;
    filename1 = sprintf('bfs_vol_profile_%d_bus.fig', num_buses);
    filename2 = sprintf('bfs_vol_profile_%d_bus.png', num_buses);
    savefig(fig, fullfile(pwd, 'Figures', filename1));
    exportgraphics(gcf, fullfile(pwd, 'Figures', filename2), 'Resolution', 300);
    close(fig);
    
    % Plot the maximum voltage error vs. computation time till iteration
    fig = figure;
    plot(cumulative_iter_times, max_voltage_errors, '-o', 'LineWidth', 2);
    set(gca, 'FontName', 'Palatino Linotype'); 
    xlabel('Computation Time (seconds)', 'FontName', 'Palatino Linotype');
    ylabel('Maximum Error', 'FontName', 'Palatino Linotype');
    title('Maximum Error vs. Computation Time', 'FontName', 'Palatino Linotype');
    % grid on;
    filename1 = sprintf('bfs_maxE_Comp_%d_bus.fig', num_buses);
    filename2 = sprintf('bfs_maxE_Comp_%d_bus.png', num_buses);
    savefig(fig, fullfile(pwd, 'Figures', filename1));
    exportgraphics(gcf, fullfile(pwd, 'Figures', filename2), 'Resolution', 300);
    close(fig);
    
    % Write results to a text file with UTF-8 encoding
    fid_txt = fopen(sprintf('Result_files/bfs_bus_voltage_%d_bus.txt', num_buses), 'w', 'n', 'UTF-8');
    fprintf(fid_txt, 'Converged in %d iterations.\n\n', iteration);
    fprintf(fid_txt, 'Bus Voltages:\n');
    % Print aligned column headers
    fprintf(fid_txt, '%-12s %-12s %-12s %-12s %-12s\n', ...
        'Bus Number', 'Real', 'Imaginary', 'Magnitude', 'Angle');
    % Print each row of bus voltage data, aligned under headers
    for i = 1:num_buses
        fprintf(fid_txt, '%-12d %-12.4f %-12.4f %-12.4f %-12.2f\n', ...
            i, real(v(i)), imag(v(i)), abs(v(i)), rad2deg(angle(v(i))));
    end
    fclose(fid_txt);
    
    % Write results to a CSV file with writetable, you can also use fopen
    % but everything would be changed from txt to csv
    T = table((1:num_buses)', real(v), imag(v), abs(v), rad2deg(angle(v)), ...
    'VariableNames', {'Bus_Number', 'Real', 'Imaginary', 'Magnitude', 'Angle'});

    writetable(T, sprintf('Result_files/bfs_bus_voltage_%d_bus.csv', num_buses));

end
