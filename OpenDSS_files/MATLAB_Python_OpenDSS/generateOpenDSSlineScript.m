function openDSS_script = generateOpenDSSlineScript(line_data, phases)
    % Initialize an empty string to hold the full script
    openDSS_script = "";
    
    % Iterate over each line in the line_data
    for i = 1:size(line_data, 1)
        % Extract data for each line
        sending = line_data(i, 1);
        receiving = line_data(i, 2);
        R = line_data(i, 3);
        X = line_data(i, 4);
        
        % Format the OpenDSS command for this line
        line_command = sprintf('New Line.Line%d bus1=%d bus2=%d phases=%d R1=%f X1=%f\n', ...
                               i, sending, receiving, phases, R, X);
        
        % Append the line command to the full script, adding a new line after each entry
        openDSS_script = openDSS_script + line_command;
    end
    
    % Display the full OpenDSS script in the command window
    disp(openDSS_script)
    
end
