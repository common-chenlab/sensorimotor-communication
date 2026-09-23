function rrr = run_comparison(Ca, tr_include,all)

[c2 ia2 ib2] = intersect(tr_include{1}, all.trialno, 'stable');
all.all = all.all(ib2);
all.choice = all.choice(ib2);
all.stim = all.stim(ib2);
tr_include{1} = tr_include{1}(ia2);
sampletime = [95:125];
testtime = [242:272];
%build data
probe = [];
goal = [];
for j = 1:length(Ca.deconv_REF)
    probe = [probe, nanmean(Ca.deconv_REF{j}(:,sampletime),2)];
    goal = [goal, nanmean(Ca.deconv_REF{j}(:,testtime),2)];
end

% goal = [];
% for j = 1:length(Ca.deconv_REF)  
%     goal = [goal; Ca.deconv_REF{j}(:,1:350)];
% end



rrr = [];
for k = 1:4
    if k == 1  % A lick vs A no lick
        ix1 = find(all.all>(3/100)&all.stim<3);
        ix2 = find(all.all<=(3/100)&all.stim<3);
    elseif k == 2  % P lick vs P no lick
        ix1 = find(all.all>(3/100)&all.stim>2);
        ix2 = find(all.all<=(3/100)&all.stim>2);
    elseif k == 3  % A lick vs P lick
        ix1 = find(all.all>(3/100)&all.stim<3);
        ix2 = find(all.all>(3/100)&all.stim>2);
    elseif k == 4  % A no lick vs P no lick
        ix1 = find(all.all<=(3/100)&all.stim<3);
        ix2 = find(all.all<=(3/100)&all.stim>2);
    end
    for i = 1:size(probe,1)
        [h p] = ttest2(probe(i,ix1),probe(i,ix2),'tail','right'); 
        rrr(i,2*k-1) = p;
        [h p] = ttest2(probe(i,ix1),probe(i,ix2),'tail','left'); 
        rrr(i,2*k) = p;
    end
end

for k = 5:8
    if k == 5  % A lick vs A no lick
        ix1 = find(all.choice==1);
        ix2 = find(all.choice==2);
    elseif k == 6  % P lick vs P no lick
        ix1 = find(all.choice==4);
        ix2 = find(all.choice==3);
    elseif k == 7  % A lick vs P lick
        ix1 = find(all.choice==1);
        ix2 = find(all.choice==4);
    elseif k == 8  % A no lick vs P no lick
        ix1 = find(all.choice==2);
        ix2 = find(all.choice==3);
    end
    for i = 1:size(goal,1)
        [h p] = ttest2(goal(i,ix1),goal(i,ix2),'tail','right'); 
        rrr(i,2*k-1) = p;
        [h p] = ttest2(goal(i,ix1),goal(i,ix2),'tail','left'); 
        rrr(i,2*k) = p;
    end
end

