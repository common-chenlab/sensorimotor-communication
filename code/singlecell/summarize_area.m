function [a, b] = summarize_area(S1,ref)

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
a = [];
for i = 1:12
    a(i) = sum(r==i)/length(r);
end
% for i = 1:12
%     if i == 1 || i == 2
%         a(i) = sum(r==i)/sum(r==1|r==2);
%     elseif i == 3 || i == 4
%         a(i) = sum(r==i)/sum(r==3|r==4);
%     elseif i > 4 && i <9
%         a(i) = sum(r==i)/sum(r>4&r<9);
%     elseif i > 8
%         a(i) = sum(r==i)/sum(r>8);
%     end
% end

r = [];
for i = 1:size(rS1,1)
%     [corrected_p, h]=bonf_holm(rS1(i,9:16),0.05);
    h = rS1(i,9:16)<0.05;
    %     hS1(i,:) =  h;
    h = find(ismember(ref,double(h),'rows'));
    if isempty(h)
        r(i) = 0;
    else
        r(i) = h;
    end
end
b = [];
for i = 1:12
    b(i) = sum(r==i)/length(r);
end
% for i = 1:12
%     if i == 1 || i == 2
%         b(i) = sum(r==i)/sum(r==1|r==2);
%     elseif i == 3 || i == 4
%         b(i) = sum(r==i)/sum(r==3|r==4);
%     elseif i > 4 && i <9
%         b(i) = sum(r==i)/sum(r>4&r<9);
%     elseif i > 8
%         b(i) = sum(r==i)/sum(r>8);
%     end
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