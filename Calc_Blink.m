function Calc_Blink(taskname)
addpath scripts
blink_res = calc_blink(taskname);
save(fullfile('EOG', sprintf('blink_res_%s', taskname)), 'blink_res', '-v7.3', '-nocompression')
rmpath scripts
end
