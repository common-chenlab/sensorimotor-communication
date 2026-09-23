function [M2, cM2] = normcorre_chen_batch(Y, do_nonrigid)

if ~exist('do_nonrigid', 'var')
    do_nonrigid = 0;
end

Y = single(Y);                 % convert to single precision

maxXshift = 30;
maxYshift = 50;

% ///// p x q spatial binning of original movie
p = 2;
q = 2;
Y1 = imresize3(Y, 'scale', [1/p, 1/q, 1]);

options_rigid = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),'bin_width',30, ...
    'max_shift',[maxXshift/p, maxYshift/q],'us_fac',2,'use_parallel',true);

%tic;
[~,shifts0,~] = normcorre(Y1,options_rigid); 
%toc

% /// update shift vector for original movie
analyze_shifts = [];
shift2_new = shifts0;
for i = 1:size(Y1,3)
    shift2_new(i).shifts    = [p,q]'.*shifts0(i).shifts;
    shift2_new(i).shifts_up = [p,q]'.*shifts0(i).shifts_up;
    analyze_shifts = [analyze_shifts, shift2_new(i).shifts];
end

max_shift_x = max(diff(analyze_shifts(1,:)));
max_shift_y = max(diff(analyze_shifts(2,:)));

if max_shift_x > maxXshift || max_shift_y > maxYshift
    analyze_shifts(1,:) = medfilt1(analyze_shifts(1,:),3,'truncate');
    analyze_shifts(2,:) = medfilt1(analyze_shifts(2,:),3,'truncate');
    max_shift_x = max(diff(analyze_shifts(1,:)));
    max_shift_y = max(diff(analyze_shifts(2,:)));
end

if max_shift_x > 50 || max_shift_y > 65
    disp(analyze_shifts)
    M2  = [];  % error in video file, pass empty return
    cM2 = [];
elseif do_nonrigid
    Y2 = apply_shifts(Y,shift2_new,options_rigid);

    % now try non-rigid motion correction (also in parallel) % for ~ [200 519]
    options_nonrigid = NoRMCorreSetParms('d1',size(Y2,1),'d2',size(Y2,2),'grid_size',[100,100],'mot_uf',4,'bin_width',60,...
        'max_shift',25,'max_dev',25,'us_fac',4, 'min_patch_size', [16 16 16], 'overlap_post',[25,25,16],'use_parallel',true, ...
        'boundary', 'copy');

    tic; M2 = normcorre_batch(Y2,options_nonrigid); toc

    cM2 = motion_metrics(M2,10);
else
    M2 = apply_shifts(Y,shift2_new,options_rigid);
    cM2 = motion_metrics(M2,5);
end