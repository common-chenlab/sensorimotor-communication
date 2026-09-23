function sm_assert_writable()
% SM_ASSERT_WRITABLE  Stop before a pipeline script writes into the lab's working data.
%
%   The upstream pipeline scripts (perform_CCA_sub, export_CCA_data, get_CCA_coef,
%   LoadCCA) save into the data tree returned by smroot(). That is fine for a
%   downloaded copy of the data, but when smroot() falls back to the Chen lab
%   Dropbox/claustrum copy those files are the originals the paper was made from.
%   Set SM_ALLOW_WRITE=1 to override deliberately.

root = lower(strrep(smroot(), '\', '/'));
is_lab_copy = contains(root, 'chen lab team folder/projects/sensorimotor');
if is_lab_copy && ~strcmp(getenv('SM_ALLOW_WRITE'), '1')
    error('sm:readOnlyData', ['This script writes into %s, which is the lab''s working copy of the data.\n' ...
        'Run it against a separate copy (SM_DATA_ROOT or <repo>/data), or set SM_ALLOW_WRITE=1.'], smroot());
end
end
