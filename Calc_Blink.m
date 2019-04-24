function Calc_Blink(taskname)
addpath scripts
data_path = 'EOG';
load(fullfile(data_path, sprintf('EOG_%s.mat', taskname))); %#ok<LOAD>
blink_res = calc_blink(EOG);
save(fullfile(data_path, sprintf('blink_res_%s', taskname)), 'blink_res', '-v7.3', '-nocompression')
rmpath scripts
end
