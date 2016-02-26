clear,clc
%Get access to the data files.
parpath = fileparts(pwd);
datapath = [parpath, filesep, 'ResData'];
%Access to all files.
dataFilesInfo = dir([datapath, filesep, 'EOG*']);
dataFilesName = {dataFilesInfo.name};
thisFile = [datapath, filesep, dataFilesName{9}];
cblink(thisFile)
