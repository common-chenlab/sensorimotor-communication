"""Hand-written edits applied to repository copies after the automatic path rewrite.

Keys are repository paths; each patch must match exactly `count` times (default 1)
in the rewritten text, otherwise build_repo.py stops. Patches only touch file
locations (inputs that depended on MATLAB's current folder, and output folders);
the analysis code itself is unchanged. Every patched line is marked "[release]".
"""

PROJ = "[smroot() 'Analysis/proj/full-resid_stim/']"
GUARD = ("sm_assert_writable(); % [release] this script writes into the data tree; "
         "refuses to run against the lab's working copy\n")


def result_dir(out_name, legacy):
    """Outputs go to results/<out_name>; reads fall back to the copy shipped in data/."""
    return (f"outdir = smout('{out_name}'); % [release] outputs -> results/{out_name}\n"
            f"if ~isfile([outdir '{{file}}']), outdir = [smroot() '{legacy}']; end % [release] fall back to shipped results")


PATCHES = {
    'code/pipeline_cca/setup_SM_workspace.m': [
        # The lab's session-tracking table is not deposited. summary.mat holds the same
        # session lists: control (the 44 sessions the paper uses) and c21 (32 C21 sessions,
        # used by no figure). Sessions the lab excluded are simply absent from it.
        {'find': "animal_table = ChenLab2Ptable('Sensorimotor', animal, 'update',false);"
                 " % ChenLab2Ptable('Sensorimotor', 'sm045', 'update',true);\n"
                 "n_session_max = max(cellfun(@height, animal_table));\n"
                 "animal_fig_dir = cell(1,n_animal);\n"
                 "sessions = repmat(struct('all',[], 'use',[], 'ctrl',[], 'dreadd',[]), 1, n_animal);\n"
                 "for an = 1:n_animal\n"
                 "    sessions(an).all = 1:max(animal_table{an}.Im_Session);\n"
                 "    sessions(an).ctrl = find(~animal_table{an}.C21)';\n"
                 "    sessions(an).dreadd = find(animal_table{an}.C21)';\n"
                 "    sessions(an).exclude = find(animal_table{an}.Exclude);\n"
                 "    sessions(an).use = find(animal_table{an}.trials_exist & ...\n"
                 "        animal_table{an}.A0_step == 7 & animal_table{an}.A1_step == 7 &"
                 " animal_table{an}.A2_step == 7 & animal_table{an}.A3_step == 7)';\n"
                 "    sessions(an).use( ismember(sessions(an).use,sessions(an).exclude) ) = [];\n",
         'replace': "% [release] the lab session table (ChenLab2Ptable) crawled the acquisition servers and is\n"
                    "% [release] not deposited. summary.mat holds the same lists: control = the 44 sessions the\n"
                    "% [release] paper uses, c21 = the 32 C21 sessions no figure uses. Excluded sessions are\n"
                    "% [release] absent from it, so sessions(an).exclude is empty.\n"
                    "sess_list = load([smroot() 'Analysis/summary.mat'], 'control', 'c21'); % [release]\n"
                    "animal_table = []; % [release] lab bookkeeping table, not deposited\n"
                    "animal_fig_dir = cell(1,n_animal);\n"
                    "sessions = repmat(struct('all',[], 'use',[], 'ctrl',[], 'dreadd',[], 'exclude',[]), 1, n_animal);\n"
                    "for an = 1:n_animal\n"
                    "    sessions(an).ctrl = sort([sess_list.control{strcmp(sess_list.control(:,1), animal{an}), 2}]); % [release]\n"
                    "    sessions(an).dreadd = sort([sess_list.c21{strcmp(sess_list.c21(:,1), animal{an}), 2}]); % [release]\n"
                    "    sessions(an).exclude = []; % [release]\n"
                    "    sessions(an).use = sort([sessions(an).ctrl, sessions(an).dreadd]); % [release]\n"
                    "    sessions(an).all = 1:max([sessions(an).use, 0]); % [release]\n"},
        {'find': "    animal_fig_dir{an} = sprintf([smroot() 'Animals/%s/Figures/'], animal{an});",
         'replace': "    animal_fig_dir{an} = [smroot() 'Animals' filesep animal{an} filesep 'Figures' filesep];"
                    " % [release] was sprintf, which read a Windows data root's backslashes as escapes"},
        {'find': "end\n\nend", 'replace': "end\nn_session_max = max(arrayfun(@(s)(max([s.use, 0])), sessions)); % [release] was the lab table's height\n\nend"},
    ],
    # ---------------------------------------------------------------- cwd-relative inputs
    'code/cca/COMPARE_CCA_SUBSPACE.m': [
        {'find': "files = dir('*.mat');",
         'replace': f"files = dir([{PROJ[1:-1]} '*.mat']); % [release] was dir('*.mat') run from proj/full-resid_stim"},
        {'find': "load(filename,'CCA_coeff');",
         'replace': f"load([{PROJ[1:-1]} filename],'CCA_coeff'); % [release]"},
    ],
    'code/cca/DISPLAY_sig_CCA.m': [
        {'find': "load([control{m,1} '-' num2str(control{m,2}) '-CCA_proj_full-resid_stim.mat']);",
         'replace': f"load([{PROJ[1:-1]} control{{m,1}} '-' num2str(control{{m,2}}) '-CCA_proj_full-resid_stim.mat']); % [release]"},
    ],
    'code/svm_cca/SVM_CCA_alignment.m': [
        {'find': "load([control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat'])",
         'replace': f"load([{PROJ[1:-1]} control{{p,1}} '-' num2str(control{{p,2}}) '-CCA_proj_full-resid_stim.mat']) % [release]",
         'count': 2},
    ],
    'code/svm_cca/SVM_CCA_alignment_UI.m': [
        {'find': "load([control{p,1} '-' num2str(control{p,2}) '-CCA_proj_full-resid_stim.mat'])",
         'replace': f"load([{PROJ[1:-1]} control{{p,1}} '-' num2str(control{{p,2}}) '-CCA_proj_full-resid_stim.mat']) % [release]",
         'count': 4},
    ],
    'code/behavior_whisker/whisker_analysis_delay.m': [
        {'find': "load('matlab.mat')",
         'replace': "load([smroot() 'Analysis/whisker_analysis/matlab.mat']) % [release] was load('matlab.mat') from whisker_analysis/"},
    ],
    'code/behavior_whisker/whisking_preprobe_pregoal_stat.m': [
        {'find': "load('matlab.mat','result');",
         'replace': "load([smroot() 'Analysis/whisker_analysis/matlab.mat'],'result'); % [release]"},
    ],
    'code/singlecell/FIGURE_RASTER.m': [
        {'find': "load('sm052-3.mat')",
         'replace': "load([smroot() 'Animals/sm052/sm052-3.mat']) % [release] was load('sm052-3.mat') from Animals/sm052/"},
    ],
    'code/reviewer_svm_ablation/SVM_ABLATION.m': [
        {'find': "mch = [pre 'mCherry\\'];", 'replace': "mch = [pre 'mCherry/']; % [release] portable separator"},
        {'find': "outdir = [smroot() 'Analysis/R1C1_svm_ablation/'];",
         'replace': "outdir = smout('reviewer_svm_ablation'); % [release] outputs -> results/"},
    ],

    # ---------------------------------------------------------------- outputs -> results/
    'code/reviewer_svm_ablation/DISPLAY_svm_ablation.m': [
        {'find': "outdir = [smroot() 'Analysis/R1C1_svm_ablation/'];",
         'replace': result_dir('reviewer_svm_ablation', 'Analysis/R1C1_svm_ablation/').format(file='SVM_ablation_results.mat')},
        {'find': "print(gcf, [outdir 'FigR1C1_svm_ablation']",
         'replace': "print(gcf, [smout('reviewer_svm_ablation') 'FigR1C1_svm_ablation']", 'count': 2},
    ],
    'code/cca_subspace_reference/CCA_SUBSPACE_REFERENCE.m': [
        {'find': "outdir = [smroot() 'Analysis/CCA_SUBSPACE_REVISION/'];",
         'replace': "outdir = smout('cca_subspace_reference'); % [release] outputs -> results/"},
    ],
    'code/cca_subspace_reference/DISPLAY_subspace_reference.m': [
        {'find': "outdir = [smroot() 'Analysis/CCA_SUBSPACE_REVISION/'];",
         'replace': result_dir('cca_subspace_reference', 'Analysis/CCA_SUBSPACE_REVISION/').format(file='CCA_subspace_reference_results.mat')},
        {'find': "print(gcf, [outdir 'FigS_subspace_reference_MATLAB']",
         'replace': "print(gcf, [smout('cca_subspace_reference') 'FigS_subspace_reference_MATLAB']", 'count': 2},
    ],
    'code/dimensionality/DIMENSIONALITY_ANALYSIS.m': [
        {'find': "OUT = [smroot() 'Analysis/R1C3_dimensionality/'];",
         'replace': "OUT = smout('dimensionality'); % [release] outputs -> results/"},
    ],
    'code/svm_cca/FIG5_STATS.m': [
        {'find': "OUTDIR  = fileparts(mfilename('fullpath'));",
         'replace': "OUTDIR  = smout('fig5_stats'); % [release] was the script's own folder"},
    ],
    'code/ifi/FIG7E_STATS.m': [
        {'find': "OUTDIR  = fileparts(mfilename('fullpath'));",
         'replace': "OUTDIR  = smout('fig7e_stats'); % [release] was the script's own folder"},
    ],

    'code/behavior_lick/plot_choice_FIGURE.m': [
        {'find': "x = 1:4;\ndata = nanmean(control,1);",
         'replace': "load([smroot() 'Analysis/fig1b_opto/choice.mat'], 'control') % [release] was loaded by hand from Figure1-Opto/choice.mat\n"
                    "x = 1:4;\ndata = nanmean(control,1);"},
    ],

    # ---------------------------------------------------------------- server reads
    'code/lib/chenlab/LoadMultiFOV.m': [
        {'find': "    mkdir(ChenLabFilepath(sprintf('%s%s\\\\Figures\\\\', source_dir, animal)));\n",
         'replace': "    % [release] per-FOV figure folders go under results/, not into the data tree\n"},
        {'find': "        fov(a).fig_dir = ChenLabFilepath(sprintf('%s%s\\\\Figures\\\\%s\\\\', source_dir, animal, fov(a).name));\n"
                 "        mkdir(fov(a).fig_dir); %[smroot() 'Animals/']\n",
         'replace': "        fov(a).fig_dir = smout(sprintf('figures/%s/%s', animal, fov(a).name)); % [release] was <data>/Animals/<animal>/Figures/\n"},
        {'find': "    % Read parameters.xml file\n    [~,behav_dir] = FileFinder(ChenLabFilepath(sprintf('%s%s\\\\2P\\\\%s-%i\\\\',W_dir, animal, animal, sess)), 'type',0, 'contains','Behavior');\n    [~, params_path] = FileFinder(behav_dir{1}, 'type','xml', 'contains','parameters');\n    %fprintf('\\nReading %s', params_path{1})\n    params = parseXML(params_path{1}); % xmlread\n    stage_params = params.Children(strcmpi({params.Children.Name}, 'stage'));\n",
         'replace': "    % [release] the deposited session files carry these values as CaA<k>.xml_params, written\n    % [release] by tools/build_session_file.m from the acquisition server's parameters.xml.\n    if ~isfield(data_struct.CaA0, 'xml_params') % [release]\n        error('sm:noXmlParams', ['%s has no CaA<k>.xml_params, so it predates the deposited ' ...\n            'dataset. That field holds the field-of-view parameters that earlier versions read ' ...\n            'from parameters.xml on the lab acquisition server. Use the deposited session ' ...\n            'files, or rebuild this one with tools/build_session_file.m.'], mat_path); % [release]\n    end % [release]\n"},
        {'find': "        area_params = params.Children(string({params.Children.Name}) == sprintf('area%i',a-1)); % 'area0'\n        arm_params = area_params.Children(strcmpi({area_params.Children.Name}, 'framearm'));\n        fov(a).params.Framerate_Hz = area_params.Children(string({area_params.Children.Name}) == 'Framerate_Hz').Children.Data;\n        fpu_xy = area_params.Children(string({area_params.Children.Name}) == 'fpuxystage').Children;\n        fov(a).params.Xpos = str2double( fpu_xy(strcmpi({fpu_xy.Name}, 'XPosition_um') ).Children.Data ); % fpuxystage -> XPosition_um\n        fov(a).params.Ypos = str2double( fpu_xy(strcmpi({fpu_xy.Name}, 'YPosition_um') ).Children.Data ); % fpuxystage -> YPosition_um\n        % 2 versions of offsets appear under the framearm node, USE THE SECOND PAIR\n        fov(a).params.Xoffset = str2double( arm_params.Children(find(strcmpi({arm_params.Children.Name}, 'XOffset_Fraction'),1, 'last')).Children.Data );\n        fov(a).params.Yoffset = str2double( arm_params.Children(find(strcmpi({arm_params.Children.Name}, 'YOffset_Fraction'),1, 'last')).Children.Data );\n        fov(a).params.Xstage = str2double( stage_params.Children((strcmpi({stage_params.Children.Name}, 'XPosition_um'))).Children.Data );\n        fov(a).params.Ystage = str2double( stage_params.Children((strcmpi({stage_params.Children.Name}, 'YPosition_um'))).Children.Data );\n",
         'replace': "        fov(a).params = rmfield(fov_data{a}.xml_params, 'source'); % [release] was parsed from parameters.xml on the acquisition server\n"},
    ],

    # ---------------------------------------------------------------- scripts that write into data/
    'code/pipeline_cca/export_CCA_data.m': [
        # The lab ran this after perform_CCA_sub, in the same MATLAB session and with the loop
        # bounds edited by hand to whatever was being re-exported. For the deposit it has to
        # stand on its own and cover the sessions the paper uses.
        {'find': "% Select the model to export\nmodel_name = 'full-resid_stim_std';"
                 " %'peri90-win15-step3-correct';  %\n",
         'replace': GUARD +
                    "if ~exist('animal', 'var') % [release] the lab had these from perform_CCA_sub\n"
                    "    [animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max,"
                    " sessions, animal_fig_dir] = setup_SM_workspace(); % [release]\n"
                    "end % [release]\n"
                    "if ~exist('trials', 'var') || ~iscell(trials) % [release] filled in per session below\n"
                    "    trials = cell(n_animal, n_session_max); fov = cell(n_animal, n_session_max); % [release]\n"
                    "end % [release]\n"
                    "% Select the model to export\n"
                    "model_name = 'full-resid_stim'; % [release] was 'full-resid_stim_std', a variant no figure"
                    " uses; the published model is full-resid_stim\n"},
        {'find': "for an = 2 %1:n_animal % flip( )\n"
                 "    for sess = 4 % intersect(sessions(an).use, sessions(an).dreadd)"
                 " % intersect(sessions(an).use, sessions(an).dreadd)\n",
         'replace': "for an = 1:n_animal % [release] was an = 2, the session the author last re-exported\n"
                    "    for sess = intersect(sessions(an).use, sessions(an).ctrl) % [release] was sess = 4\n"},
        {'find': "        CCA_result = LoadCCA(animal{an}, sess, model_name, true, false);\n"
                 "        CCA_params = reshape([CCA_result.params], size(CCA_result));"
                 " % get the parameters that were used when the model was originally run",
         'replace': "        CCA_result = LoadCCA(animal{an}, sess, model_name, true, false);\n"
                    "        if isempty(CCA_result) % [release] the emptiness check below comes too late:"
                    " the next line already indexes into CCA_result\n"
                    "            fprintf(' - no %s results, skipping', model_name); continue % [release]\n"
                    "        end % [release]\n"
                    "        CCA_params = reshape([CCA_result.params], size(CCA_result));"
                    " % get the parameters that were used when the model was originally run"},
        # The projection save below needs act_resid, which is only computed in the branch that
        # writes the preprocessing file. After perform_CCA_sub has run, that branch is skipped
        # and the save fails, silently, because the catch prints no reason.
        {'find': "                else\n                    warning('%s already exists! - skipping', preproc_path)\n",
         'replace': "                else\n"
                    "                    fprintf('\\nLoading %s', preproc_path)"
                    " % [release] the projection save below needs act_resid from it\n"
                    "                    load(preproc_path, 'act_resid') % [release]\n"},
        {'find': "            catch\n                fprintf('\\n%s-%i failed', animal{an}, sess)",
         'replace': "            catch err % [release] say why, instead of just \"failed\"\n"
                    "                fprintf('\\n%s-%i failed: %s', animal{an}, sess, err.message) % [release]",
         'count': 3},
        {'find': "for r = 63:n_result\n",
         'replace': "for r = 1:n_result % [release] was r = 63, where a previous run had been resumed\n"},
    ],
    'code/pipeline_cca/perform_CCA_sub.m': [
        {'find': "% Setup/housekeeping - must run the first block of gather_SM_data first!\n",
         'replace': GUARD + "% Setup/housekeeping - must run the first block of gather_SM_data first!\n"},
        # Excluded trials (missing data, excessive alignment shift) reach the CCA: the line that
        # dropped them in align_activity is commented out and CanonicalCrossCorrelationSubtype
        # ignores params.tr_exclude. The archived proj files have them dropped (275 trials for
        # sm045-4, not 276), so the published figures predate this. Dropping them here rather
        # than in align_activity keeps that file's absolute trial indexing intact.
        {'find': "                        if isfinite(CCA_params.n_PC)\n",
         'replace': "                        act_cca = cellfun(@(x)(x(:,:,tr_include{ev})), act_cca,"
                    " 'UniformOutput',false); % [release] excluded trials must not be fitted or projected\n"
                    "                        if isfinite(CCA_params.n_PC)\n"},
        {'find': "[animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max,"
                 " sessions, animal_fig_dir] = setup_SM_workspace();",
         'replace': "[animal, n_animal, fov_name, n_fov, comp, decis_name, animal_table, n_session_max,"
                    " sessions, animal_fig_dir] = setup_SM_workspace();\n"
                    "fig_dir = smout('figures'); % [release] the figure cells below use fig_dir, which the"
                    " lab got from add_sm_paths"},
    ],
    'code/pipeline_cca/get_CCA_coef.m': [
        {'find': "load('summary.mat', 'control')\n",
         'replace': GUARD + "load([smroot() 'Analysis/summary.mat'], 'control') % [release] was load('summary.mat') from Analysis/\n"},
    ],
    'code/pipeline_cca/LoadCCA.m': [
        # Name-only calls (gather_only) build a stub params struct with just name and n_align,
        # so the run_mat line below errored on CCA_params.comp whenever the model file was
        # missing, which is what a reader meets on the first session.
        {'find': "    run_mat = false(CCA_params.n_align, CCA_params.comp.n);"
                 " % % when gather only is set, don't run any further analyses",
         'replace': "    if isfield(CCA_params, 'comp') % [release] a name-only call has no comp field\n"
                    "        run_mat = false(CCA_params.n_align, CCA_params.comp.n);"
                    " % % when gather only is set, don't run any further analyses\n"
                    "    else % [release]\n"
                    "        run_mat = false; % [release] gather_only never runs anything anyway\n"
                    "    end % [release]"},
        {'find': "save_dir{2,1} = ChenLabFilepath(sprintf('Z:\\\\Projects\\\\Sensorimotor\\\\Animals\\\\%s\\\\CCA\\\\', animal));"
                 " % save here when using SCC to avoid write permission issues with dropbox\n"
                 "save_dir{1,1} = ChenLabFilepath(sprintf([smroot() 'Animals/%s/CCA/'], animal));",
         'replace': "save_dir{1,1} = ChenLabFilepath([smroot() 'Animals' filesep animal filesep 'CCA' filesep]);"
                    " % [release] was sprintf, which read a Windows data root's backslashes as escapes\n"
                    "save_dir{2,1} = save_dir{1,1};"
                    " % [release] was the lab cluster's own copy of the data tree, which readers do not have"},
        {'find': "        save(mat_path, 'CCA', '-v7.3')",
         'replace': "        sm_assert_writable(); % [release]\n        save(mat_path, 'CCA', '-v7.3')"},
    ],
}
