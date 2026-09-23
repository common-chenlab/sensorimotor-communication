function build_suppress_table(sessions)
% BUILD_SUPPRESS_TABLE  Extract the silenced-neuron lists from the lab's variant files.
%
%   build_suppress_table()               every session that has variant files
%   build_suppress_table({'sm045-4'})    only the listed sessions
%
%   Reads CCA_params.roi_suppress from each lab file
%   Analysis/preprocessing/mCherry/<session>_preprocess_pca_suppress_<variant>.mat
%   and writes the lists to the repository's data/ folder as
%   data/Analysis/preprocessing/mCherry/suppress_rois.mat, which sm_suppress_rois reads.
%   Together with the baseline preprocessing files this replaces the 120 variant files
%   (see code/data_access/sm_load_preprocess.m). The lab files are only read.

LAB = 'Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\Projects\Sensorimotor\';
src = [LAB 'Analysis\preprocessing\mCherry\'];
repo = fileparts(fileparts(mfilename('fullpath')));
out = fullfile(repo, 'data', 'Analysis', 'preprocessing', 'mCherry', 'suppress_rois.mat');

variants = {'mch', 'ctrl', 'noncherry'};
if nargin < 1 || isempty(sessions)
    d = dir([src '*_preprocess_pca_suppress_mch.mat']);
    sessions = extractBefore({d.name}, '_preprocess');
end
sessions = cellstr(sessions);

suppress_rois = struct('session', {}, 'variant', {}, 'roi', {}, 'source_md5', {});
for i = 1:numel(sessions)
    for v = 1:numel(variants)
        f = sprintf('%s%s_preprocess_pca_suppress_%s.mat', src, sessions{i}, variants{v});
        if ~isfile(f)
            warning('build_suppress_table:missing', 'missing %s', f);
            continue
        end
        p = load(f, 'CCA_params');
        suppress_rois(end+1) = struct('session', sessions{i}, 'variant', variants{v}, ...
            'roi', {p.CCA_params.roi_suppress}, 'source_md5', md5file(f)); %#ok<AGROW>
    end
end

readme = ['Silenced-neuron lists for the in-silico silencing variants (Fig 6f,g, R1.1 SVM ' ...
    'ablation). roi{a} indexes area a''s ROI list (1 S1, 2 S2, 3 M1A, 4 M1B). Extracted from ' ...
    'CCA_params.roi_suppress of the lab files by tools/build_suppress_table.m; ctrl lists are ' ...
    'the random draws actually used. source_md5 identifies the file each list came from.'];
if ~isfolder(fileparts(out)), mkdir(fileparts(out)); end
save(out, 'suppress_rois', 'readme');
fprintf('Wrote %d lists (%d sessions) to %s\n', numel(suppress_rois), numel(sessions), out);
end


function h = md5file(f)
md = java.security.MessageDigest.getInstance('MD5');
fid = fopen(f, 'r');
c = onCleanup(@() fclose(fid));
while true
    buf = fread(fid, 2^24, '*uint8');
    if isempty(buf), break; end
    md.update(buf);
end
h = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'))', 1, []));
end
