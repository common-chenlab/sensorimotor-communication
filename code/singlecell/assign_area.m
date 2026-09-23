function r = assign_area(rS1,ref)

% hS1 = [];
r = [];
for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,1:8),0.05);
    h = rS1(i,1:8)<0.05;
    %     hS1(i,:) =  h;
    h = find(ismember(ref,double(h),'rows'));
    if isempty(h)
        r(i,1) = 0;
    else
        r(i,1) = h;
    end
end

for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,9:16),0.05);
    h = rS1(i,9:16)<0.05;
    %     hS1(i,:) =  h;
    h = find(ismember(ref,double(h),'rows'));
    if isempty(h)
        r(i,2) = 0;
    else
        r(i,2) = h;
    end
end