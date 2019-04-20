function Extract_EOG(taskname)
addpath scripts
EOG = extract_eog(taskname);
save(fullfile('EOG', sprintf('EOG_%s', taskname)), 'EOG', '-v7.3', '-nocompression')
rmpath scripts
