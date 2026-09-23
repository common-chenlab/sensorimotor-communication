function ok = verify_compare_tables(label, new, ref, tol)
% VERIFY_COMPARE_TABLES  Compare two tables column by column (numeric within tol, text exactly).
if nargin < 4, tol = 1e-9; end
ok = isequal(size(new), size(ref)) && isequal(new.Properties.VariableNames, ref.Properties.VariableNames);
if ~ok
    fprintf('%s: FAIL - table shape/columns differ (%s vs %s)\n', label, mat2str(size(new)), mat2str(size(ref)));
    return
end
worst = 0;
for v = new.Properties.VariableNames
    a = new.(v{1}); b = ref.(v{1});
    if isnumeric(a) && isnumeric(b)
        d = abs(a - b);
        d(isnan(a) & isnan(b)) = 0;
        if any(isnan(d)), d(isnan(d)) = inf; end
        worst = max([worst; d(:)]);
        if any(d(:) > tol)
            fprintf('%s: column %s differs (max abs diff %g)\n', label, v{1}, max(d(:)));
            ok = false;
        end
    elseif ~isequal(string(a), string(b))
        fprintf('%s: column %s differs (text)\n', label, v{1});
        ok = false;
    end
end
if ok
    fprintf('%s: PASS - %d rows x %d columns identical (max numeric diff %g)\n', label, height(new), width(new), worst);
end
end
