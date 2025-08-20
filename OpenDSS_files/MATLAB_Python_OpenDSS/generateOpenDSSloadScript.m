function openDSS_load_script = generateOpenDSSloadScript(load_data, phases, kv)
    % Initialize an empty string to hold the full script
    openDSS_load_script = "";
    
    % Iterate over each line in the line_data
    for i = 2:size(load_data, 1)
        % Extract data for each line
        bus_number = load_data(i, 1);
        P = load_data(i, 2);
        Q = load_data(i, 3);
        
        % Format the OpenDSS command for this line
        load_command = sprintf('New Load.Load%d bus1=%d phases=%d kv=%.2f kw=%.2f kvar=%.2f\n', ...
                               i-1, bus_number, phases, kv, P, Q);
        
        % New Load.Load1 bus1=2 phases=1 kv=12.66 kw=100 kvar=60                    
        % Append the line command to the full script, adding a new line after each entry
        openDSS_load_script = openDSS_load_script + load_command;
    end
    
    % Display the full OpenDSS script in the command window
    disp(openDSS_load_script)
    
end
