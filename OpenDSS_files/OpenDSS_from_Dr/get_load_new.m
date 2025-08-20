

% opening file to write 
fileID = fopen('mynewload.dss','w');
for i=1:length(Pload) 
    
    LoadData = [i;i;Pload(i);Qload(i)];
    formatSpec ='New Load.L%d  bus1=%d  model=1 phases=1 conn=wye kv=0.24 kW=%6.6f kvar=%6.6f Vminpu=0.1 Vmaxpu=1.1\n';
    fprintf(fileID,formatSpec,LoadData);

end

fclose(fileID);