function pclust = setup_parpool_SCC(temp_folder)
if nargin == 0, temp_folder = ''; end % example default location: /usr/<user>/.matlab/local_cluster_jobs/R2021b/
if ~ischar(temp_folder), error('temp_folder must be a char'), end
%  setup parallel processing for SCC
if isunix
    NUM_CPUS = str2double(getenv('NSLOTS'));
    if isempty(gcp('nocreate')) || gcp('nocreate').NumWorkers ~= NUM_CPUS
        delete(gcp('nocreate'));
        maxNumCompThreads(NUM_CPUS); %limits the max number of threads to the number of cpus given on scc
        pclust = parcluster('local');
        parpool_tmpdir = fullfile(pclust.JobStorageLocation, temp_folder, filesep); 
        mkdir(parpool_tmpdir);
        pclust.JobStorageLocation = parpool_tmpdir;
        parpool(pclust, NUM_CPUS);
    end
else
    %warning('setup_parpool_SCC called in non-unix environment - skipping')
    pclust = [];
end
end