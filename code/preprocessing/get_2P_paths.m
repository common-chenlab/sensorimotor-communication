function paths_struct = get_2P_paths(main_drive, proj, varargin) % animal, sess, subsession, 
check_text = @(x)(ischar(x) || isstring(x) || isempty(x));
check_sess = @(x)(ischar(x) || isstring(x) || isnumeric(x));
IP = inputParser;
addRequired( IP, 'main_drive', check_text ) % %main_drive = 'V:\';
addRequired( IP, 'proj', check_text ) % 'Transsynaptic'
addOptional( IP, 'animal', '', check_text )  
addOptional( IP, 'sess', [], check_sess )
addOptional( IP, 'subsession', '', check_text )
addParameter( IP, 'must_exist', true, @islogical ) % require that paths/files must actually exist to be included in paths_struct?
addParameter( IP, 'db_drive', 'Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder\', check_text )
parse( IP, main_drive, proj, varargin{:} ); % area_num, animal, sess, subsession, 
animal = IP.Results.animal;
sess = IP.Results.sess;
subsession = IP.Results.subsession;
must_exist = IP.Results.must_exist;
db_drive = IP.Results.db_drive;
main_drive = upper(main_drive);
if numel(main_drive) == 1, main_drive = [main_drive,':\']; end
if ~isnumeric(sess), sess = str2double(sess); end

if ~isempty(subsession) %subsession - this is the trickiest case as dropbox and local versions differ - based on CHEN_2P_Pipeline_Step_01
    error('subsession case currently disabled')
elseif numel(sess) > 1
    error('more than one session provided')
elseif ~isempty(sess) %session dirs (no subsession)
    sess_name = sprintf('%s-%i',animal, sess);
    paths_struct = struct( 'animal',animal,...
        'session',sess,...
        'sess_name',sess_name, ...
        'main_anm','',...
        'main_dir','',...
        'main_mat','',...
        'main_2P','',...
        'main_sess','',...
        'main_pre','',...
        'db_proj', '',...
        'db_anm','',...
        'db_dir','',...
        'db_mat','' );
    % Main drive paths
    [main_anm, ~] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\', main_drive, proj) ); % main_anm_exists
    paths_struct.main_anm = main_anm;
    [main_dir, main_dir_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\%s\\', main_drive, proj, animal) );
    if main_dir_exists || ~must_exist
        paths_struct.main_dir = main_dir;
        % Find the session's mat file
        [main_mat_path, main_mat_exists] = ChenLabFilepath( sprintf('%s\\%s.mat', main_dir, sess_name) );
        if main_mat_exists || ~must_exist,  paths_struct.main_mat =  main_mat_path; end
        % Find the 2P subfolder
        [main_2P_dir, main_2P_exists] = ChenLabFilepath( sprintf('%s\\2P\\', main_dir) ); 
        if main_2P_exists || ~must_exist
            paths_struct.main_2P =  main_2P_dir;
            % Find the session's preprocessing dir
            [main_sess_dir, main_sess_exists] = ChenLabFilepath( sprintf('%s\\%s\\', main_2P_dir, sess_name) );
            if main_sess_exists || ~must_exist
                paths_struct.main_sess =  main_sess_dir;
                [preproc_dir, preproc_exists] = ChenLabFilepath( sprintf('%s\\PreProcess\\', main_sess_dir) );
                if preproc_exists || ~must_exist, paths_struct.main_pre =  preproc_dir; end
            end
        end
    end
    % Dropbox paths
    [db_proj, db_proj_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\', db_drive, proj) );
    if db_proj_exists || ~must_exist
        paths_struct.db_proj = db_proj;
    end

    [db_anm, db_anm_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\', db_drive, proj) );
    if db_anm_exists || ~must_exist
        paths_struct.db_anm = db_anm;
        [db_dir, db_dir_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\%s\\', db_drive, proj, animal) );
        if db_dir_exists || ~must_exist
            paths_struct.db_dir = db_dir;
            % Find the session's mat file
            [db_mat_path, db_mat_exists] = ChenLabFilepath( sprintf('%s\\%s.mat', db_dir, sess_name) );
            if db_mat_exists || ~must_exist,  paths_struct.db_mat =  db_mat_path; end
        end
    end
elseif ~isempty(animal) % animal dirs
    paths_struct = struct( 'main_dir','', 'main_2P','', 'db_anm','', 'db_dir','' ); 
    [main_dir, main_dir_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\%s\\', main_drive, proj, animal) );
    if main_dir_exists || ~must_exist, paths_struct.main_dir = main_dir;  end
    [main_2P_dir, main_2P_exists] = ChenLabFilepath( sprintf('%s\\2P\\', main_dir) );
    if main_2P_exists || ~must_exist,  paths_struct.main_2P =  main_2P_dir;  end
    [db_anm, db_anm_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\Animals\\', db_drive, proj) );
    if db_anm_exists || ~must_exist, paths_struct.db_anm = db_anm; end
    [db_dir, db_dir_exists] = ChenLabFilepath( sprintf('%s\\Animals\\%s\\', db_anm, animal) );
    if db_dir_exists || ~must_exist, paths_struct.db_dir = db_dir; end
else % project dirs only
    paths_struct = struct( 'main_dir','', 'main_anm','', 'db_proj','', 'db_anm','' ); % db_proj formerly db_dir
    [main_dir, main_dir_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\', main_drive, proj) );
    if main_dir_exists || ~must_exist, paths_struct.main_dir = main_dir;  end
    [main_an_dir, main_an_exists] = ChenLabFilepath( sprintf('%s\\Animals\\', main_dir) );
    if main_an_exists || ~must_exist, paths_struct.main_anm = main_an_dir;  end

    [db_proj, db_proj_exists] = ChenLabFilepath( sprintf('%s\\Projects\\%s\\', db_drive, proj) );
    if db_proj_exists || ~must_exist, paths_struct.db_proj = db_proj; end
    [db_anm_dir, db_anm_exists] = ChenLabFilepath( sprintf('%s\\Animals\\', db_proj) );
    if db_anm_exists || ~must_exist, paths_struct.db_anm = db_anm_dir;  end
end

end