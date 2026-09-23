function [animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max, sessions, animal_fig_dir] = setup_SM_workspace()
% Name the animals included in analysis
animal = {'sm041','sm045','sm052','sm054','sm056','sm057'}; %
n_animal = numel(animal);

fov_name = {'S1','S2','M1_A','M1_B'};
n_fov = numel(fov_name);
comp = make_comparison_struct(fov_name); % Setup fov-fov comparisons
decis_name = ["Hit","CR","Miss","FA"];

% Identify useful subsets of sessions
% [release] the lab session table (ChenLab2Ptable) crawled the acquisition servers and is
% [release] not deposited. summary.mat holds the same lists: control = the 44 sessions the
% [release] paper uses, c21 = the 32 C21 sessions no figure uses. Excluded sessions are
% [release] absent from it, so sessions(an).exclude is empty.
sess_list = load([smroot() 'Analysis/summary.mat'], 'control', 'c21'); % [release]
animal_table = []; % [release] lab bookkeeping table, not deposited
animal_fig_dir = cell(1,n_animal);
sessions = repmat(struct('all',[], 'use',[], 'ctrl',[], 'dreadd',[], 'exclude',[]), 1, n_animal);
for an = 1:n_animal
    sessions(an).ctrl = sort([sess_list.control{strcmp(sess_list.control(:,1), animal{an}), 2}]); % [release]
    sessions(an).dreadd = sort([sess_list.c21{strcmp(sess_list.c21(:,1), animal{an}), 2}]); % [release]
    sessions(an).exclude = []; % [release]
    sessions(an).use = sort([sessions(an).ctrl, sessions(an).dreadd]); % [release]
    sessions(an).all = 1:max([sessions(an).use, 0]); % [release]
    animal_fig_dir{an} = [smroot() 'Animals' filesep animal{an} filesep 'Figures' filesep]; % [release] was sprintf, which read a Windows data root's backslashes as escapes %mkdir(fig_dir{an});
end
n_session_max = max(arrayfun(@(s)(max([s.use, 0])), sessions)); % [release] was the lab table's height

end