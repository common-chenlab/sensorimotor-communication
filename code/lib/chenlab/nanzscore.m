function zscore = nanzscore(X, dim)
%
Xmean = mean(X, dim, 'omitnan');
Xstd = std(X, 0, dim, 'omitnan');

zscore = (X-Xmean)./Xstd;

end

