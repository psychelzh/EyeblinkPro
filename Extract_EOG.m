function Extract_EOG(taskname)
addpath scripts
EOG = extract_eog(taskname);
save(fullfile('EOG', sprintf('EOG_%s', taskname)), 'EOG')
rmpath scripts
