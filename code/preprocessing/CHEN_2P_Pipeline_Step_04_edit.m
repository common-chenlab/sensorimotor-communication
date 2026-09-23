%%  //////////////////////////////////// CHEN_2P_Pipeline_Step_04 /////////////////////////////////////
% Purpose: annotation of ROIs (cell types and repeatedly imaged neurons)
function CHEN_2P_Pipeline_Step_04_edit(pathdirectory, animal, session_num,area_channel) %, area_num, varargin) % static_channel, activity_channel, skipflip

sessionName   = [animal , '-', session_num];          % e.g.'jn018-1'; full session name
sessionfile   = [sessionName '.mat'];            % file destination for save
savefoldername = fullfile(pathdirectory, animal);
 
load([savefoldername '\' sessionfile]);
  
if isempty(findstr(area_channel, 'A0')) == 0
    Ca = CaA0;
elseif isempty(findstr(area_channel, 'A1')) == 0
    Ca = CaA1;
elseif isempty(findstr(area_channel, 'A2')) == 0
    Ca = CaA2;
elseif isempty(findstr(area_channel, 'A3')) == 0
    Ca = CaA3;
end

try
    temp = atan(Ca.celltype_ration_REF)-atan(cell2mat(Ca.celltype_REF(:,2))./cell2mat(Ca.celltype_REF(:,1)));
    temp = temp-prctile(temp,5);
    idx = find(cell2mat(Ca.celltype_REF(:,1))<prctile(cell2mat(Ca.celltype_REF(:,1)),20));
    temp(idx) = 0;
catch
    temp = zeros(size(data,2),1);
end

Ca.celltype_REF_new = temp>0.2;

if isempty(findstr(area_channel, 'A0')) == 0
    CaA0 = Ca;
    save([savefoldername '\' sessionfile], 'CaA0','-append', '-v6'); disp(['successfully save CaA0 to ' sessionfile])
elseif isempty(findstr(area_channel, 'A1')) == 0
    CaA1 = Ca;
    save([savefoldername '\' sessionfile], 'CaA1','-append', '-v6');
elseif isempty(findstr(area_channel, 'A2')) == 0
    CaA2 = Ca;
    save([savefoldername '\' sessionfile], 'CaA2','-append', '-v6'); disp(['successfully save CaA2 to ' sessionfile])
elseif isempty(findstr(area_channel, 'A3')) == 0
    CaA3 = Ca;
    save([savefoldername '\'  sessionfile], 'CaA3','-append', '-v6');
end
