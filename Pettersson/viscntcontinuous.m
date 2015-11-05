function visualres = viscntcontinuous(datafile, start)
%VISUALCOUNT plot the data for visual inspection to count eye blinks.

%By Zhang, Liang, 2015/11/4.

%Check input parameters.
if nargin == 1
    start = 1;
end

%Load data.
load(datafile);

%Plot each of the EOG data and stop for visual inspection.
datalength = length(EOGv);
fprintf('found %d subjects.\n', datalength);
%1st column: participant id; 2nd column: number of blinks; 3rd column: task
%duration (min); 4th column: note about the data.
reslabel = {'PID', 'NumBlink', 'Duration', 'Note'};
visualcountres = cell(datalength, 4);
%Error handling.
try
    for isub = start:datalength
        fprintf('now processing %d...\n', EOGv(isub).pid);
        if ~isempty(EOGv(isub).trial)
            %Plot data with the eeglab gui.
            eegplot(EOGv(isub).trial{1}, ...
                'srate'    , EOGv(isub).fsample, ...
                'spacing'  , 1000, ...
                'winlength', 20, ...
                'title'    , ['Sub ' num2str(EOGv(isub).pid)]);
            %Wait until user close the gui.
            uiwait(gcf)
            %User input its counting result.
            inputprompt    = {'How many blinks?', 'Note'};
            inputtitle     = 'Computer Record';
            num_lines      = [1 10; 1 50];
            defans         = {'nan', ''};
            options.Resize = 'off';
            userinput      = inputdlg(inputprompt, inputtitle, num_lines, defans, options);
            nblink = str2double(userinput{1});
            dur = round(EOGv(isub).time{1}(end) / 60, 2);
            note = userinput{2};
        else
            nblink = nan;
            dur = nan;
            note = '';
        end
        visualcountres{isub, 1} = EOGv(isub).pid;
        visualcountres{isub, 2} = nblink;
        visualcountres{isub, 3} = dur;
        visualcountres{isub, 4} = note;
    end
catch
    fprintf('error found when processing subject %d, #%d.\n', EOGv(isub).pid, isub);
end
xlswrite(sprintf('nblink_%s.xlsx', datestr(now, 'HH-MM')), [reslabel; visualcountres]);
if nargout == 1, visualres = visualcountres; end