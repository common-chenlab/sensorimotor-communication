function act_decat_z = standardize_multitrial( act_trial )
% act_trial = activity of each trial: # timepoints x # ROIs x # of trials
[n_frame, n_ROI, n_trial] = size(act_trial);


act_cat = reshape(act_trial, [], n_ROI, 1);
act_cat_z = normalize(act_cat); %standardize along concatenated columns (ROIs)

%act_decat_z = reshape(act_cat_z', n_frame, n_ROI, n_trial);


act_decat_z = nan(n_frame, n_ROI, n_trial);
for tr = 1:n_trial
    curr_frames = (tr-1)*size(act_trial,1) + [1:n_frame];
    act_decat_z(:,:,tr) = act_cat_z(curr_frames,:);
end

%{
figure;
tiledlayout('flow')
nexttile
imagesc(act_cat(1:size(act_trial,1),:,1)')

nexttile
imagesc(act_cat_z(1:size(act_trial,1),:,1)')

nexttile
imagesc(act_decat_z(:,:,1)')

nexttile
imagesc(act_cat_z(1:size(act_trial,1),:,1)' - act_decat_z(:,:,1)')

impixelinfo
%}



end