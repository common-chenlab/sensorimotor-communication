% LIST_TOOLBOXES  MATLAB products required by the repository code, and any
% function it calls that is found neither in the repository nor in MATLAB.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(repo, 'startup_sm.m'));

files = dir(fullfile(repo, 'code', '**', '*.m'));
paths = fullfile({files.folder}, {files.name});
[req, products] = matlab.codetools.requiredFilesAndProducts(paths);

fprintf('\nRequired products:\n');
for k = 1:numel(products)
    fprintf('  %-45s %s\n', products(k).Name, products(k).Version);
end
outside = req(~startsWith(req, repo));
fprintf('\nRequired files outside the repository: %d\n', numel(outside));
fprintf('  %s\n', outside{:});
