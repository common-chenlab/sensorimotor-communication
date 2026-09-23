function info = build_session_file(animal, sess, out_root, varargin)
% BUILD_SESSION_FILE  Write the cleaned, compressed copy of one session for the GIN dataset.
%
%   info = build_session_file('sm045', 4, 'W:\Projects\Sensorimotor\GIN')
%
% Reads <src>/Animals/<animal>/<animal>-<sess>.mat and _whisker.mat (read-only) and writes
% <out_root>/Animals/<animal>/ copies that
%   - keep only the fields the deposited analysis code reads, plus small provenance fields
%     (keep-list traced 2026-09-21, see the data README's variable table),
%   - add CaA<k>.xml_params: the per-area stage and offset parameters that LoadMultiFOV
%     otherwise reads from parameters.xml on the acquisition server,
%   - are saved with -v7 compression (lossless).
% Every kept field is reloaded and compared with isequaln against the source.
%
% Options: 'src_root' (default smroot()), 'xml_root' (default the W: acquisition tree),
%          'overwrite' (default false).

p = inputParser;
addParameter(p, 'src_root', smroot(), @(x) ischar(x) || isstring(x));
addParameter(p, 'xml_root', 'W:\Projects\Sensorimotor\Animals\', @(x) ischar(x) || isstring(x));
addParameter(p, 'overwrite', false, @islogical);
parse(p, varargin{:});
o = p.Results;

TOP_KEEP = {'CaA0', 'CaA1', 'CaA2', 'CaA3', 'trials', 'summary', 'licks'};
TOP_DROP = {'writing'};
CA_KEEP = {'F_df_REF', 'deconv_REF', 'ROIs_REF', 'cellid_REF', 'celltype_REF', ...
    'celltype_REF_angle', 'celltype_REF_new', 'celltype_angle_thres', 'celltype_ration_REF', ...
    'ROIs', 'cellid', 'notch', 'sampling_rate', 'sessionfoldername', 'trial_info', 'FOV', ...
    'deconv_params', 'CNMFOptions', 'params'};   % params: sm057-5 only
CA_DROP = {'s_oasis', 'b', 'b_dp', 'F_dF', 'celltype', 'cellalgo', 'ref_trial', ...
    'trial_noise', 'bad_trials_deconv', ...
    'artifact', 'offset'};   % left over from the obsolete subtract_artifact.m crosstalk correction

name = sprintf('%s-%d', animal, sess);
src_dir = fullfile(char(o.src_root), 'Animals', animal);
out_dir = fullfile(char(out_root), 'Animals', animal);
src_mat = fullfile(src_dir, [name '.mat']);
src_whk = fullfile(src_dir, [name '_whisker.mat']);
out_mat = fullfile(out_dir, [name '.mat']);
out_whk = fullfile(out_dir, [name '_whisker.mat']);

% Never write next to the lab's working copy.
if startsWith(lower(canon(out_dir)), lower(canon(src_dir))) || ...
        contains(lower(canon(out_dir)), lower(canon(fullfile('Chen Lab Dropbox'))))
    error('build_session_file:unsafe', 'Refusing to write into the lab data tree: %s', out_dir);
end
if ~o.overwrite && (isfile(out_mat) || isfile(out_whk))
    error('build_session_file:exists', '%s exists; pass ''overwrite'', true', out_mat);
end
if ~isfolder(out_dir), mkdir(out_dir); end

% ---- session file ------------------------------------------------------------------------
fprintf('Loading %s\n', src_mat); t = tic;
S = load(src_mat);
fprintf('  loaded in %.0f s\n', toc(t));

vars = fieldnames(S);
unknown = setdiff(vars, [TOP_KEEP TOP_DROP]);
if ~isempty(unknown)
    error('build_session_file:unknown', '%s: unexpected variable(s) %s', name, strjoin(unknown, ', '));
end
missing = setdiff(TOP_KEEP, vars);
if ~isempty(missing)
    error('build_session_file:missing', '%s: missing variable(s) %s', name, strjoin(missing, ', '));
end

xml = read_xml_params(char(o.xml_root), animal, sess);

out = struct();
for v = setdiff(TOP_KEEP, {'CaA0', 'CaA1', 'CaA2', 'CaA3'}, 'stable')
    out.(v{1}) = S.(v{1});
end
dropped = {};
for k = 0:3
    ca = sprintf('CaA%d', k);
    f = fieldnames(S.(ca));
    unknown = setdiff(f, [CA_KEEP CA_DROP]);
    if ~isempty(unknown)
        error('build_session_file:unknown', '%s.%s: unexpected field(s) %s', name, ca, strjoin(unknown, ', '));
    end
    keep = intersect(CA_KEEP, f, 'stable');      % M1 labelling fields exist only in CaA2/3
    out.(ca) = struct();
    for i = 1:numel(keep)
        out.(ca).(keep{i}) = S.(ca).(keep{i});
    end
    out.(ca).xml_params = xml(k + 1);
    dropped = [dropped, reshape(strcat(ca, '.', intersect(CA_DROP, f, 'stable')), 1, [])]; %#ok<AGROW>
end

check_v7_limits(out, name);
fprintf('Saving %s\n', out_mat); t = tic;
save(out_mat, '-struct', 'out', '-v7');
fprintf('  saved in %.0f s\n', toc(t));

% ---- whisker file: unchanged content, recompressed ---------------------------------------
W = load(src_whk);
check_v7_limits(W, [name '_whisker']);
save(out_whk, '-struct', 'W', '-v7');

% ---- verify ------------------------------------------------------------------------------
R = load(out_mat);
assert(isequal(sort(fieldnames(R)), sort(fieldnames(out))), 'variable list changed on save');
for v = fieldnames(out)'
    if startsWith(v{1}, 'CaA')
        for g = setdiff(fieldnames(out.(v{1})), {'xml_params'})'
            assert(isequaln(R.(v{1}).(g{1}), S.(v{1}).(g{1})), '%s.%s differs from source', v{1}, g{1});
        end
        assert(isequaln(R.(v{1}).xml_params, xml(str2double(v{1}(end)) + 1)), '%s.xml_params', v{1});
    else
        assert(isequaln(R.(v{1}), S.(v{1})), '%s differs from source', v{1});
    end
end
assert(isequaln(load(out_whk), W), 'whisker file differs from source');

info = struct('session', name, ...
    'src_MB', [fsize(src_mat), fsize(src_whk)] / 1e6, ...
    'out_MB', [fsize(out_mat), fsize(out_whk)] / 1e6, ...
    'dropped', {dropped}, 'strings', {collect_paths(R)});
fprintf('%s: %.0f MB -> %.0f MB, whisker %.0f MB -> %.0f MB, verified\n', name, ...
    info.src_MB(1), info.out_MB(1), info.src_MB(2), info.out_MB(2));
end

% ------------------------------------------------------------------------------------------
function xml = read_xml_params(xml_root, animal, sess)
% Same extraction as LoadMultiFOV: the first trial's Behavior folder, area<k> nodes, the
% second XOffset/YOffset pair under framearm. Types match what LoadMultiFOV produces
% (Framerate_Hz stays text), so a patched loader can use these values unchanged.
sess_dir = fullfile(xml_root, animal, '2P', sprintf('%s-%d', animal, sess));
d = dir(fullfile(sess_dir, '*Behavior*'));
d = d([d.isdir]);
if isempty(d), error('build_session_file:xml', 'No Behavior folder in %s', sess_dir); end
[~, first] = sort({d.name});
xml_path = fullfile(sess_dir, d(first(1)).name, 'parameters.xml');
params = parseXML(xml_path);
stage = params.Children(strcmpi({params.Children.Name}, 'stage'));
val = @(node, nm) node.Children(strcmpi({node.Children.Name}, nm)).Children.Data;
xml = struct([]);
for k = 0:3
    area = params.Children(string({params.Children.Name}) == sprintf('area%i', k));
    arm = area.Children(strcmpi({area.Children.Name}, 'framearm'));
    fpu = area.Children(string({area.Children.Name}) == 'fpuxystage');
    x.Framerate_Hz = area.Children(string({area.Children.Name}) == 'Framerate_Hz').Children.Data;
    x.Xpos = str2double(val(fpu, 'XPosition_um'));
    x.Ypos = str2double(val(fpu, 'YPosition_um'));
    x.Xoffset = str2double(arm.Children(find(strcmpi({arm.Children.Name}, 'XOffset_Fraction'), 1, 'last')).Children.Data);
    x.Yoffset = str2double(arm.Children(find(strcmpi({arm.Children.Name}, 'YOffset_Fraction'), 1, 'last')).Children.Data);
    x.Xstage = str2double(val(stage, 'XPosition_um'));
    x.Ystage = str2double(val(stage, 'YPosition_um'));
    x.source = sprintf('%s/%s/parameters.xml', sprintf('%s-%d', animal, sess), d(first(1)).name);
    xml = [xml, x]; %#ok<AGROW>
end
end

function check_v7_limits(s, name)
% -v7 cannot store a variable larger than 2 GB (uncompressed).
for v = fieldnames(s)'
    x = s.(v{1}); w = whos('x');
    if w.bytes >= 2^31
        error('build_session_file:v7', '%s.%s is %.2f GB, over the -v7 limit', name, v{1}, w.bytes / 2^30);
    end
end
end

function b = fsize(f)
d = dir(f); b = d.bytes;
end

function p = canon(p)
p = strrep(char(p), '/', '\');
end

function out = collect_paths(x)
% Distinct strings that look like file paths, for the private-information scan.
out = {};
if ischar(x) || isstring(x)
    s = cellstr(x);
    s = reshape(s, 1, []);
    out = s(~cellfun(@isempty, regexp(s, '([A-Za-z]:\\|/net/|/home/|/usr|\\\\)', 'once')));
elseif iscell(x)
    for i = 1:numel(x), out = [out, collect_paths(x{i})]; end %#ok<AGROW>
elseif isstruct(x)
    for f = fieldnames(x)'
        for i = 1:numel(x), out = [out, collect_paths(x(i).(f{1}))]; end %#ok<AGROW>
    end
end
out = unique(out);
end
