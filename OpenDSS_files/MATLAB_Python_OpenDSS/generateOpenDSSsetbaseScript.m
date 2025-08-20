function openDSS_setbase_script = generateOpenDSSsetbaseScript(load_data, kv)
    % Initialize an empty string to hold the full script
    openDSS_setbase_script = "";
    
    % Iterate over each line in the line_data
    for i = 1:size(load_data, 1)
        % Extract data for each line
        bus_number = load_data(i, 1);
           
        % Format the OpenDSS command for this line
        setbase_command = sprintf('SetkVBase Bus  = %d kVLL=%.2f\n', bus_number, kv);
                 
        % Append the line command to the full script, adding a new line after each entry
        openDSS_setbase_script = openDSS_setbase_script + setbase_command;
    end
    
    % Display the full OpenDSS script in the command window
    disp(openDSS_setbase_script)
    
end