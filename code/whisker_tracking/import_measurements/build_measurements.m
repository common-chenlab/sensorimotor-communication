function [sort_whiskers, sort_measurements] = build_measurements(whiskers, measurements) 

% whisker_count = 1;
% frames = 0;
% 
% for i = 1:length(measurements)
%     
%     if frames == measurements(i).fid
%     else
%         whisker_count = 1;
%         frames = frames + 1;
%     end
%     sort_whiskers(whisker_count, measurements(i).fid+1) = whiskers(i);
%     sort_measurements(whisker_count, measurements(i).fid+1) = measurements(i);
%     whisker_count = whisker_count + 1;
% end

whisker_count = 1;
frames = 0;
%% Preallocate
fidn=length(unique([measurements.fid]));
whik_max=max(diff(find(diff([measurements.fid])==1)));
M=cell(whik_max, fidn);
  sort_whiskers=struct('id' ,M, 'time', M, 'x',M ,'y',M , 'thick', M, 'scores',M );
   sort_measurements=struct('fid' ,M, 'wid', M, 'label',M ,'face_x',M ,'face_y',M ,...
       'length', M, 'score',M , 'angle', M, 'curvature', M, 'follicle_x', M, 'follicle_y',M,...
       'tip_x', M,  'tip_y', M);
   %%%%%%%%%%
for i = 1:length(measurements)
    
    if frames == measurements(i).fid
    else
        whisker_count = 1;
        frames = frames + 1;
    end
    sort_whiskers(whisker_count, measurements(i).fid+1) = whiskers(i);
   sort_measurements(whisker_count, measurements(i).fid+1) = measurements(i);
    whisker_count = whisker_count + 1;
end