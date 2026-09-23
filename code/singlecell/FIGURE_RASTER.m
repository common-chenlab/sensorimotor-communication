
% rrr = [];
% for i = 1:13
%     load(['sm052-' num2str(i) '.mat'])
%     rrr = [rrr; length(CaA0.ROIs_REF), length(CaA1.ROIs_REF), length(CaA2.ROIs_REF), length(CaA3.ROIs_REF)];
% end

load([smroot() 'Animals/sm052/sm052-3.mat']) % [release] was load('sm052-3.mat') from Animals/sm052/

aaa = [];
for i = 1:length(CaA0.F_df_REF)
    temp0 = CaA0.F_df_REF{i};
    temp1 = CaA1.F_df_REF{i};
    temp2 = CaA2.F_df_REF{i};    
    temp3 = CaA3.F_df_REF{i};    
    temp0 = resample(temp0,size(temp2,2),size(temp0,2),'Dimension',2);
    temp1 = resample(temp1,size(temp2,2),size(temp1,2),'Dimension',2);
    temp3 = resample(temp3,size(temp2,2),size(temp3,2),'Dimension',2);
    bbb = [temp0; temp1; temp2; temp3];
    ccc(1:size(bbb,1),1:30) = NaN;
    
    aaa = [aaa, bbb, ccc];
end

aaa = -nanzscore(aaa')';
aaa(isnan(aaa)) = 0;
