function [beta_corr, high, low] = get_corr_beta(corr_map, t_delay)
beta_corr = [];
high = [];
low = [];
if ~isempty(corr_map)
    Y = permute(corr_map, [2,1,3,4]);
    Y = reshape(Y, size(Y,1), []);
    X = [ones(size(Y,1),1), t_delay']; % IFI_params.
    beta_corr = X\Y; % intercept and slope for each column
    beta_corr = reshape(beta_corr, [2,size(corr_map,[1,3,4])]);
    shuf = [];
    for i = 1:1000
        X = [ones(size(Y,1),1), t_delay(randperm(length(t_delay)))'];
        temp = X\Y; % intercept and slope for each column
        shuf(:,:,:,:,i)  = reshape(temp, [2,size(corr_map,[1,3,4])]);
    end

    high = prctile(shuf,95,5);
    low = prctile(shuf,5,5);
    %
    % plot(beta_corr(2,:,1,3))
    % hold on
    % plot(low(2,:,1,3))
    % plot(high(2,:,1,3))
end
