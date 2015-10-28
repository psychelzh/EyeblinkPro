function EOGv = prepro(datapath)
%This function is used to do some prepocessing for all the EEG data stored
%in .bdf (Biosemi) files using FieldTrip. EOG data is extracted and stored
%in the generated file EOG.mat as variable EOGv, which is a structure
%stored 4 pieces of information in its 4 fields:
%   1. Subject ID;
%   2. Sampling rate; (When prepocessing, resampling is done, so this is
%   not the original sampling rate.)
%   3. Four epochs of EEG data (EOG only);
%   4. Time information of each epoch.

%Access to filenames.
filesInfo = dir([datapath, '\*.bdf']);
filesName = {filesInfo.name};
subid = str2double(regexp(filesName, '\d{4}', 'match', 'once'));
for ifile = 1:length(filesName)
    try
        %Configuration for trial definition.
        cfg                     = [];
        cfg.dataset             = [datapath, '\', filesName{ifile}];
        cfg.channel             = {'EXG3' 'EXG4'};
        cfg.trialdef.eventtype  = 'STATUS';
        cfg.trialdef.eventvalue = 63;
        cfg.trialdef.prestim    = 1;
        cfg.trialdef.poststim   = 60;
        cfg        = ft_definetrial(cfg);
        %Configuration for filtering.
        cfg.bpfilter            = 'yes';
        cfg.bpfreq              = [0.5 20];
        cfg.bpfilttype          = 'fir';
        dataPrepro = ft_preprocessing(cfg);
        %Configuration for resampling.
        cfg                     = [];
        cfg.resamplefs          = 256;
        cfg.detrend             = 'no';
        dataPrepro = ft_resampledata(cfg, dataPrepro);
        %In accordance with Li's suggestion, the first 3 seconds are abondoned.
        %Notice the first second is before the stimulus.
        start_point = floor(dataPrepro.fsample * 4);
        %Calculate the vertical EOG data.
        EOGv(ifile).pid     = subid(ifile); %#ok<*AGROW>
        EOGv(ifile).fsample = dataPrepro.fsample;
        EOGv(ifile).trial = cell(size(dataPrepro.trial)); 
        EOGv(ifile).time = cell(size(dataPrepro.trial));
        for triali = 1:length(dataPrepro.trial)    
            EOGv(ifile).trial{triali} = dataPrepro.trial{triali}(1, start_point:end) - dataPrepro.trial{triali}(2, start_point:end);
            EOGv(ifile).time{triali}  = dataPrepro.time{triali}(start_point:end);            
        end        
    catch
        fid = fopen('errlog.log', 'a');
        fprintf(fid, 'Error found while reading file %s.\n', [datapath, '\', filesName{ifile}]);
        EOGv(ifile).pid     = subid(ifile);
        EOGv(ifile).fsample = dataPrepro.fsample;
        EOGv(ifile).trial   = {};
        EOGv(ifile).time    = {};
        fclose(fid);
    end
end
save EOG EOGv