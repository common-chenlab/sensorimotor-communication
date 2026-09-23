function rrr = compile_correlation(animal, session, all)

path1 = [smroot() 'Analysis/preprocessing/'];
name1 = [animal '-' session '_preprocess_pca.mat'];
load([path1 name1]);
path2 = [smroot() 'Analysis/proj/full-resid_stim/'];
name2 = [animal '-' session '-CCA_proj_full-resid_stim.mat'];

load([path2 name2],'act_proj');
ix={};
result=[];


[c2 ia2 ib2] = intersect(tr_include{1}, all.trialno, 'stable');
all.all = all.all(ib2);
all.choice = all.choice(ib2);
all.stim = all.stim(ib2);
tr_include{1} = tr_include{1}(ia2);

% ix{4} = find(all.all>(3/100)&all.stim==4); %PP
% ix{1} = find(all.all>(3/100)&all.stim<3); %AA
% ix{2} = find(all.all<=(3/100)&all.stim<3); %PA
% ix{3} = find(all.all<=(3/100)&all.stim>2); %PP
% ix{4} = find(all.all>(3/100)&all.stim>2); %AP
% ix{5} = find(all.all<=(3/100)&all.stim==1); %AA
% ix{6} = find(all.all<=(3/100)&all.stim==2); %AP
% ix{7} = find(all.all<=(3/100)&all.stim==3); %PA
% ix{8} = find(all.all<=(3/100)&all.stim==4); %PP
% ix{13} = find(all.choice==1);
% ix{14} = find(all.choice==2);
% ix{15} = find(all.choice==3);
% ix{16} = find(all.choice==4);
% ix{1} = find(all.stim<3&all.all>(3/100)); 
% ix{2} = find(all.stim<3&all.all<=(3/100)); 
% ix{3} = find(all.stim>2&all.all>(3/100));
% ix{4} = find(all.stim>2&all.all<=(3/100));
% ix{5} = find((all.stim==1|all.stim==3)&(all.choice==1|all.choice==4)); %PA
% ix{6} = find((all.stim==1|all.stim==3)&(all.choice==2|all.choice==3)); %PA
% ix{7} = find((all.stim==2|all.stim==4)&(all.choice==1|all.choice==4)); %PA
% ix{8} = find((all.stim==2|all.stim==4)&(all.choice==2|all.choice==3)); %PA


ix{1} = find(all.stim<3&all.all>(3/100));
ix{2} = find(all.stim<3&all.all<=(3/100));
ix{3} = find(all.stim>2&all.all<=(3/100));
ix{4} = find(all.stim>2&all.all>(3/100));
ix{5} = find(all.choice==1);
ix{6} = find(all.choice==2);
ix{7} = find(all.choice==3);
ix{8} = find(all.choice==4);
ix{9} = [1:length(all.choice)];

% ix{1} = find(all.stim<3); 
% ix{2} = find(all.stim>2);
% ix{3} = find(all.all>(3/100)); 
% ix{4} = find(all.all<=(3/100)); 
% ix{5} = find(all.stim==1|all.stim==3); %PA
% ix{6} = find(all.stim==2|all.stim==4); %PP
% ix{7} = find(all.choice==1|all.choice==4); %PA
% ix{8} = find(all.choice==2|all.choice==3); %PP

rrr = [];
for m = 1:6
    temp = act_proj{m,1};
    temp2 = act_proj{m,2};
    temp = permute(temp,[1 3 2]);
    temp2 = permute(temp2,[1 3 2]);    
    for k = 1:length(ix)        
        for j = 1:3
            result = [];
            for i = 1:270 %size(temp,1)     298            
                r = corrcoef(temp(i,ix{k},j),temp2(i,ix{k},j));
                result(i) = r(1,2);
            end
            rrr(j,:,m,k) = result;
        end
    end
end

