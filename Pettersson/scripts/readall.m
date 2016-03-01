clear
%Read task setting information files.
ts_filesInfo = dir('ts_*');
ts_filesName = {ts_filesInfo.name};

ntask = length(ts_filesName);
allid = cell(ntask, 3);
%Basic statistics for missing files checking.
for i = 1:length(ts_filesName)
    [~, thisTask] = fileparts(ts_filesName{i});
    eval(thisTask);
    datapath = tasksetting.datapath;
    AllFilesInfo = dir(datapath);
    AllFilesName = {AllFilesInfo.name};
    curtaskloc = ~cellfun(@isempty, regexp(AllFilesName, ['^', tasksetting.dataprefix, '\w*\d{4}', tasksetting.datasuffix, '.bdf'], 'start', 'once'));
    curFilesName = AllFilesName(curtaskloc);
    allid{i, 1} = ts_filesName{i};
    curid = str2double(regexp(curFilesName, '\d{4}', 'match', 'once'));
    curid(curid < 2001 | curid > 3999) = [];
    allid{i, 2} = curid;
    allid{i, 3} = length(curid);
end

%Processing.
for i = 1:length(ts_filesName)
    fprintf('Now processing %s...\n', ts_filesName{i});
    [~, thisTask] = fileparts(ts_filesName{i});
    preproallEEG(thisTask);
end
