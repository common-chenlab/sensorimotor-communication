function SEM = SEM( sample, varargin )
% Calculates standard error of the mean for a sample (ignores NaNs)

if ~isempty(sample)
    if nargin > 1, dim = varargin{1}; else, dim = 1; end
    stdDev = std(sample, 0, dim, 'omitnan');
    N = sum(~isnan(sample), dim);
    SEM = stdDev./sqrt(N);
else
    SEM = NaN;
end
end

