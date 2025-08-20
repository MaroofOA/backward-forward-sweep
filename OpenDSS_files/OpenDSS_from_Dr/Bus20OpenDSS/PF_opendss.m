% clear all
clc
%%% import Ddec_Var only.

DSSObj=actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    disp('Unable to start openDSS Engine');
    return
end

DSSText=DSSObj.Text;
DSSCircuit=DSSObj.ActiveCircuit;
DSSBus = DSSCircuit.ActiveBus;


DSSText.Command='Compile (C:\Users\rahul\Dropbox\2021\IEE20bussystemSOCP\Bus20OpenDSS\ieee20master_r.dss)';  % Create a master file for this

%% Generation Data


DSSText.Command = 'Set VoltageBases = [4.16, ]' ; %  ! ARRAY OF VOLTAGES IN KV
DSSText.Command = 'CalcVoltageBases' ; %! PERFORMS ZERO LOAD POWER FLOW TO ESTIMATE VOLTAGE BASES


DSSText.Command = 'Set maxcontroliter=100';
DSSText.Command = 'solve mode=snap';

DSSSolution     = DSSCircuit.Solution;

DSSObj.AllowForms = false;

DSSSolution.Solve;


V_PU = DSSCircuit.AllBusVmagPU;
MytotalCircuitLosses= (DSSCircuit.Losses)/1000;



