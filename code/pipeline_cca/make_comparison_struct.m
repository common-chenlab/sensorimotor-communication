function comp = make_comparison_struct(fov_name)
if nargin < 1, fov_name = {'S1','S2','M1_A','M1_B'}; end
n_fov = numel(fov_name);
comp = struct('ind',[], 'n',[], 'name',[]);
comp.ind = nan(0,2); % translate from a1,a2 indexing to comp
c = 0;
for a1 = 1:n_fov-1
    for a2 = a1+1:n_fov
        c = c+1;
        comp.ind(c,:) = [a1, a2];
        comp.name{c} = sprintf('%s-%s', fov_name{a1}, fov_name{a2});
    end
end
comp.n = c;
end