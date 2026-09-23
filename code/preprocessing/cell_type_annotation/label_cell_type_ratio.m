function Ca = label_cell_type_ratio(Ca, selectivity)

for i = 1:length(Ca.ROIs_REF)
    ROImask = double(poly2mask(Ca.ROIs_REF{i}(:,2),Ca.ROIs_REF{i}(:,1),Ca.FOV(1),Ca.FOV(2)));
    ROImask(ROImask==0)=NaN;
    ROImask = ROImask.*selectivity;
    Ca.celltype_REF{i,3} = nanmean(ROImask(:));
end

% figure; imagesc(selectivity)
% hold on
% for i = 1:length(Ca.ROIs_REF)
% plot(Ca.ROIs_REF{i}(:,2),Ca.ROIs_REF{i}(:,1));
%     
% end