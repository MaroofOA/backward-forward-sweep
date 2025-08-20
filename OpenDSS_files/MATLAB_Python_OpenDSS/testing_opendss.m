% Load bus data and line data from text files
load_data = load('powerdata_33bus.txt');
line_data = load('linedata_33bus.txt');
phases = 1;
kv = 12.66;
% Call the BFS method
openDSS_script = generateOpenDSSsetbaseScript(load_data, kv);
