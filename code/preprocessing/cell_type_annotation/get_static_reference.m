function [sessionfoldername, avgimg] = get_static_reference(Ca, static_channel, sessionName, skipflip)

analysis_path = '../Flip';
addpath(genpath(analysis_path));
analysis_path = '../NoRMCorre-master';
addpath(genpath(analysis_path));

reference_trial = string(Ca.ref_trial);
pat = digitsPattern(2) + "-" + digitsPattern(2) + "-" + digitsPattern(2);
time_stamp = extract(reference_trial, pat);
fullname = [];
avgimg =[];
for i = 1:length(Ca.trial_info)
    if contains(Ca.trial_info{i}.fileloc, time_stamp)
        fullname = Ca.trial_info{i}.fileloc;
    end
end
%% sine warp and motion correction
if isempty(fullname) == 0
    pat = "Ch" + digitsPattern(1);
    fullname = replace(fullname, pat, static_channel);
    if ispc
        if contains(fullname, 'claustrum2')
            fullname = replace(fullname,'/net/claustrum2/mnt/data','X:');
        elseif contains(fullname, 'claustrum3')
            fullname = replace(fullname, '/net/claustrum3/mnt/data', 'W:');
        elseif contains(fullname, 'claustrum4')
            fullname = replace(fullname, '/net/claustrum4/mnt/data', 'V:');
        elseif contains(fullname, 'claustrum')
            if contains(fullname, 'data1')
                fullname = replace(fullname, '/net/claustrum/mnt/data1', 'Y:');
            else
                fullname = replace(fullname, '/net/claustrum/mnt/data', 'Z:');
            end
        end
        fullname = replace(fullname, '/', '\');
    elseif isunix
        if contains(fullname, 'Z:')
            fullname = replace(fullname, 'Z:', '/net/claustrum/mnt/data');
        elseif contains(fullname, 'Y:')
            fullname = replace(fullname, 'Y:', '/net/claustrum/mnt1/data');
        elseif contains(fullname, 'X:')
            fullname = replace(fullname, 'X:', '/net/claustrum2/mnt/data');
        elseif contains(fullname, 'W:')
            fullname = replace(fullname, 'W:', '/net/claustrum3/mnt/data');
        elseif contains(fullname, 'V:')
            fullname = replace(fullname, 'V:', '/net/claustrum4/mnt/data');
        end
        fullname = replace(fullname, '\', '/');
    end

    
    
    session_idx = findstr(fullname, sessionName);
    slash = findstr(fullname(session_idx:end), '\');
    sessionfoldername = fullname(1:session_idx+slash-1);
    
    try 
        reference_trial = Ca.ref_trial;
        channel_info = findstr('Ch', reference_trial);
        reference_trial(channel_info:channel_info+2) = static_channel;
        avgimg = double(imread([sessionfoldername 'PreProcess\' char(reference_trial)]));
    catch
        if skipflip == 1
            output.data_sined = readTiff(fullname);
            [output.data_sined, output.xshift] = fixOffsetAndDewarp(output.data_sined, 1);
        else
            output = CHEN_Flip_Signed(fullname, 0);
        end
        
        [motion_corrected, motion_metric] = normcorre_chen_batch(output.data_sined, 0);
        avgimg = mean(motion_corrected, 3);
        % don't do any scaling to return value, need to keep ratios between
        % channels valid
        avgimgwrite = uint16(65535 * (avgimg - min(avgimg(:))) / (max(avgimg(:)) - min(avgimg(:))));
        avgimg = double(avgimgwrite);
        imwrite(uint16(avgimgwrite), [sessionfoldername 'PreProcess\' reference_trial]);
    end
end
