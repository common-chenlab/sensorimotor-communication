function result = summarize_area_probe_test(S1,ref)

rS1 = []; 
for i = 1:length(S1)
    rS1 = [rS1; S1{i}];    
end


% hS1 = [];
r = [];
for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,1:8),0.05);
    h = rS1(i,1:8)<0.05;
    %     hS1(i,:) =  h;
    h = find(ismember(ref,double(h),'rows'));
    if isempty(h)
        r(i) = 0;
    else
        r(i) = h;
    end
end
% a = [];
% for i = 1:12
%     a(i) = sum(r==i)/length(r);
% end

r2 = [];
for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,9:16),0.05);
    h = rS1(i,9:16)<0.05;
    %     hS1(i,:) =  h;
    h = find(ismember(ref,double(h),'rows'));
    if isempty(h)
        r2(i) = 0;
    else
        r2(i) = h;
    end
end

result = [];
for i = 0:12
    for j = 0:12
        result(i+1,j+1) = sum(r==i&r2==j);
    end
end
result = result./sum(result,1);

% b = [];
% for i = 1:12
%     b(i) = sum(r==i)/length(r);
% end

% a = [sum(hS1(:,1:4),2)==2,sum(hS1(:,5:8),2)==2,sum(hS1,2)==1,sum([sum(hS1(:,1:4),2)==1,sum(hS1(:,5:8),2)==1],2)==2];
% a = sum(a,1);
% hS1 = [];
% for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,9:16),0.05);
%     hS1(i,:) =  h;
% end
% b = [sum(hS1(:,1:4),2)==2,sum(hS1(:,5:8),2)==2,sum(hS1,2)==1,sum([sum(hS1(:,1:4),2)==1,sum(hS1(:,5:8),2)==1],2)==2];
% b = sum(b,1);