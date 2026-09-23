function [main_dir, fig_dir] = add_sm_paths()
% ADD_SM_PATHS  Repository stand-in for the lab's Analysis Suite/PIPELINE/add_sm_paths.m.
%   The lab version added ~17 hard-coded Dropbox folders to the path. Here all code
%   is already on the path via startup_sm.m; this only returns the two folders the
%   callers expect.
main_dir = [smroot() 'Animals' filesep];
fig_dir = smout('figures');
end
