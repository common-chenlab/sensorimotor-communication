function [phase, amp, setpt] = get_hilbert_components_100(meanAng)

whiskSampRate = 100; % Sampling rate of whisker data, Hz
lpcutoff = 15; % Hz, cutoff for lowpass whisker filter
w_lp = lpcutoff*2*pi/whiskSampRate;
[b_lp,a_lp] = butter(2,w_lp,'low');

phase = [];
amp = [];
setpt = [];

% meanAng may have NaN, which is a problem for filtering & GLM
meanAng = naninterp(meanAng);
% tf = isnan(meanAng);
% maxConsNaNs = maxConsecutive(tf);
% ConsNaN_Limit = 15; % Limit of consecutive NaNs before ignoring whisker data
% NaN_Limit = 0.1*numel(meanAng); % Limit of total NaNs before ignoring whisker data
% 
% if sum(tf) < NaN_Limit && maxConsNaNs < ConsNaN_Limit
%     ix = 1:numel(meanAng);
%     meanAng(tf) = interp1(ix(~tf),meanAng(~tf),ix(tf)); % Interpolate NaNs
    
    % Low-pass filter the meanAngle signal for Hilbert
    meanAng = filtfilt(b_lp,a_lp,meanAng);
    
    % Find phase, set point, and amplitude using Hilbert transform
    bp = [4 20]; % bandpass filter for finding phase
    setpt_func = inline( '(max(x) + min (x)) / 2');
    amp_func  = @range ;
    
    phase = phase_from_hilbert( meanAng, whiskSampRate, bp );
    [amp,tops] = get_slow_var(meanAng, phase, amp_func );
    setpt = get_slow_var(meanAng, phase, setpt_func );
    reconstruction = setpt + (amp/2).*cos(phase);
end
% end
%%
function [maxCons] = maxConsecutive(x)
% Finds max consecutive elements in a vector that are >0
y = find(~(x>0)); % Indices of elements >0
diffs = diff([0 y numel(x) + 1])-1; % Distance between zero elements
maxCons = max(diffs);
end
function X = naninterp(X)
warning('off','MATLAB:interp1:UsePCHIP')
% Interpolate over NaNs
% See INTERP1 for more info
X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)),'cubic');
end               
