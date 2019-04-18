%Clear original tasksettting.
clear tasksetting

%Settings of the task Filtering.
tasksetting.datapath              = 'E:\EEG_Gene_Data\EEG_Results'; %Specify where to read the data.
tasksetting.dataprefix              = 'RLA'; %Specify which data to read.
tasksetting.datasuffix              = 'T';

%For trial definition.
tasksetting.trialpar.continuous   = 'yes';
tasksetting.trialpar.trigger      = [1 2]; 
% tasksetting.trialpar.trialprepost = [-1, 60];
tasksetting.trialpar.starttime    = 0;
tasksetting.trialpar.channel      = {'EXG3' 'EXG4' 'EXG5' 'EXG6'};
tasksetting.trialpar.minevent     = 48;

%Specify where to store data.
cur_path = fileparts(mfilename('fullpath'));
tasksetting.outpath               = [fileparts(cur_path), filesep, 'ResData'];
% Specify data prefix.
tasksetting.outdataprefix         = 'EOG_RLAT';
