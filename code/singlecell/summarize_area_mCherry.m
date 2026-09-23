function [a, b] = summarize_area_mCherry(S1,S1type,S1B,S1Btype,ref,mCherry)

rS1 = []; 
for i = 1:length(S1)
    try
    rS1 = [rS1; S1{i}(S1type{i}==mCherry,:)];    
    catch
    end
end

for i = 1:length(S1B)
    try
    rS1 = [rS1; S1B{i}(S1Btype{i}==mCherry,:)];    
    catch
    end
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

a = [];
% for i = 1:4
%     if i == 1
%         a(i) = sum(r==1|r==2)/length(r);
%     elseif i == 2        
%         a(i) = sum(r==3|r==4)/length(r);
%     elseif i == 3
%         a(i) = sum(r==5|r==6|r==7|r==8)/length(r);
%     elseif i == 4
%         a(i) = sum(r==9|r==10|r==11|r==12)/length(r);
%     end
% end

for i = 1:12
    if i == 1 || i == 2
        a(i) = sum(r==i)/sum(r==1|r==2);
    elseif i == 3 || i == 4
        a(i) = sum(r==i)/sum(r==3|r==4);
    elseif i > 4 && i <9
        a(i) = sum(r==i)/sum(r>4&r<9);
    elseif i > 8
        a(i) = sum(r==i)/sum(r>8);
    end
end

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
% b = [];
% for i = 1:12
%     b(i) = sum(r==i)/length(r);
% end
% b = [];
% for i = 1:4
%     if i == 1
%         b(i) = sum(r==1|r==2)/length(r);
%     elseif i == 2        
%         b(i) = sum(r==3|r==4)/length(r);
%     elseif i == 3
%         b(i) = sum(r==5|r==6|r==7|r==8)/length(r);
%     elseif i == 4
%         b(i) = sum(r==9|r==10|r==11|r==12)/length(r);
%     end
% end


b=[];
for i = 1:12
    if i == 1 || i == 2
        b(i) = sum(r==i)/sum(r==1|r==2);
    elseif i == 3 || i == 4
        b(i) = sum(r==i)/sum(r==3|r==4);
    elseif i > 4 && i <9
        b(i) = sum(r==i)/sum(r>4&r<9);
    elseif i > 8
        b(i) = sum(r==i)/sum(r>8);
    end
end


