%Clear original tasksettting.
clear tasksetting

%Settings of the task REST.
tasksetting.datapath              = 'E:\EEG_Gene_Data\EEG_Results'; %Specify where to read the data.
tasksetting.dataprefix              = 'REST'; %Specify which data to read.

%For trial definition.
tasksetting.trialpar.continuous   = 'no';
tasksetting.trialpar.trigger      = 3; 
tasksetting.trialpar.trialprepost = [-1, 60];
tasksetting.trialpar.starttime    = 4;
tasksetting.trialpar.channel      = {'EXG3' 'EXG4'};

%Specify where to store data.
cur_path = fileparts(mfilename('fullpath'));
tasksetting.outpath               = [fileparts(cur_path), filesep, 'ResData'];
%Specify data prefix.
tasksetting.outdataprefix         = 'EOG_REST';
