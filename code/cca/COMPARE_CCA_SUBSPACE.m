load([smroot() 'Analysis/summary.mat'])

idx = [1,1,2,1;1,1,3,1;2,1,3,1;...
    1,2,4,1;1,2,5,1;4,1,5,1;...
    2,2,4,2;2,2,6,1;4,2,6,1;...
    3,2,5,2;3,2,6,2;5,2,6,2];
labels = {'S1-S2:M1A','S1-S2:M1B','S1-M1A:M1B',...
    'S2-S1:M1A','S2-S1:M1B','S2-M1A:M1B',...
    'M1A-S1:S2','M1A-S1:M1B','M1A-S2:M1B',...
    'M1B-S1:S2','M1B-S1:M1A','M1B-S2:M1A'};

files = dir([smroot() 'Analysis/proj/full-resid_stim/' '*.mat']); % [release] was dir('*.mat') run from proj/full-resid_stim
resultc= [];
counter = 1;
for j = 1:size(control,1)
    try
        filename = [control{j,1} '-' num2str(control{j,2}) '-CCA_proj_full-resid_stim.mat'];
        load([smroot() 'Analysis/proj/full-resid_stim/' filename],'CCA_coeff'); % [release]
        j
        for k = 1:3
            for i = 1:size(idx,1)
                resultc(k,i,counter) = rad2deg(subspace(CCA_coeff{idx(i,1),idx(i,2)}(:,1:k), CCA_coeff{idx(i,3),idx(i,4)}(:,1:k)));
                %              resultc(k,i,counter) = rad2deg(subspace(CCA_coeff{idx(i,1),idx(i,2)}(:,k), CCA_coeff{idx(i,3),idx(i,4)}(:,k)));
            end
        end
        counter = counter + 1;
    catch
    end
end

% figure; bar(nanmean(resultc(1:3,:,:),3)'); title('control - subspaces'); xticklabels(labels)

% figure; bar(nanmean(resultc(2,:,:),3)'); title('control - subspaces'); xticklabels(labels)

%%

for i = 1:3
    x = 1:12;
    aaa = nanmean(resultc(i,:,:),3)';
    bbb = nanstd(resultc(i,:,:),[],3)'/sqrt(size(resultc,3));
    figure(i); bar(x,aaa)
    hold on
    er = errorbar(x,aaa,bbb,bbb);
    er.Color = [0 0 0];
    er.LineStyle = 'none';
    hold off
    ylim([0 90])
    title(['control - CC' num2str(i)]); xticklabels(labels)
end

%% PAPER FIGURE



for j = 1:3:12
    figure;
    for i = 1:3
        x = 1:3;
        aaa = nanmean(resultc(i,j:j+2,:),3)';
        bbb = nanstd(resultc(i,j:j+2,:),[],3)'/sqrt(size(resultc,3));
        errorbar(x,aaa,bbb,"-o","MarkerSize",7,...
            "MarkerEdgeColor","black","MarkerFaceColor",[0 0 0])
        hold on
    end
    hold off
    xlim([0 4])
    ylim([0 90])
    xticks([0:4]);
    xticklabels([{''},labels(j:j+2),{''}]);
end


for j = 1:3:12
    figure;
    for i = 2
        x = 1:3;
        aaa = nanmean(resultc(i,j:j+2,:),3)';
        bbb = nanstd(resultc(i,j:j+2,:),[],3)'/sqrt(size(resultc,3));
        bar(aaa)
        hold on
        errorbar(x,aaa,bbb,"-o","MarkerSize",7,...
            "MarkerEdgeColor","black","MarkerFaceColor",[0 0 0])        
    end
    hold off
    xlim([0 4])
    ylim([0 90])
    xticks([0:4]);
    xticklabels([{''},labels(j:j+2),{''}]);
end



%%

rc = permute(resultc, [2 3 1]);
p = [];
for i = 1:3
    for j = 1:4
        [h, p(1,j,i)] = ttest(rc(j*3-2,:,i),rc(j*3-1,:,i));
        [h, p(2,j,i)] = ttest(rc(j*3-2,:,i),rc(j*3,:,i));
        [h, p(3,j,i)] = ttest(rc(j*3-1,:,i),rc(j*3,:,i));

        [p(:,j,i), h]=bonf_holm(p(:,j,i),0.05);

    end
end


rc = permute(resultc, [2 3 1]);
p = [];
for i = 1:3
    for j = 1:4
        [h, p(1,j,i)] = ttest(rc(j*3-2,:,i),rc(j*3-1,:,i));
        [h, p(2,j,i)] = ttest(rc(j*3-2,:,i),rc(j*3,:,i));
        [h, p(3,j,i)] = ttest(rc(j*3-1,:,i),rc(j*3,:,i));

        [p(:,j,i), h]=bonf_holm(p(:,j,i),0.05);

    end
end
% 
% 
%  0.5606    0.9299    0.0000    0.0000
%     0.5606    0.0233    0.0049    0.0063
%     0.9377    0.0181    0.0037    0.0208
%     
%     
% 
% aaa = nanmean(resultc(3,:,:),3);
% 
% aaa=[0,	47.53434925,	43.93032868,	43.65996663;...
% 53.27574244,	0,	53.51283764,	43.98906341;...
% 46.05576312,	64.17445013,	0,	57.19404082;...
% 46.10692265,	65.28348504,	59.25252173, 0];
