function [angles, curves] = median_angle_curve(raw_folder, original_file, whisker_length, whisker_score, follicle_y_max, follicle_y_min, tip_y_max)

%             whisker_length = 60;
%             whisker_score = 70;
%             follicle_y_max = 440;
%             follicle_y_min = 50;
%             tip_y_max = 440; 

angles = [];
curves = [];



if exist([raw_folder original_file '_nofilter.mat']) ~= 0
    disp([raw_folder original_file '_nofilter.mat']);
    load([raw_folder original_file '_nofilter.mat']);
    if exist('measurements') ~= 0
        traceF=zeros(size(measurements)).*NaN;
        traceF2=zeros(size(measurements)).*NaN;
        for ind=1:size(measurements,1)
            try
                face_y = measurements(1, 1).face_y;
                face_x = measurements(1, 1).face_x;
%                 z=find([measurements(ind,:).length]>whisker_length & [measurements(ind,:).score]>whisker_score & [measurements(ind,:).follicle_y]<follicle_y_max & [measurements(ind,:).follicle_y]>follicle_y_min & [measurements(ind,:).tip_y]<tip_y_max);
                z=find([measurements(ind,:).length]>whisker_length & [measurements(ind,:).score]>whisker_score & [measurements(ind,:).follicle_y]<(face_y+100) & [measurements(ind,:).follicle_y]>(face_y-100) & [measurements(ind,:).follicle_x]<(face_x+100));
              
                  
                for z1=z
                    if ~isempty( measurements(ind,z1).angle)
                        traceF(ind,z1)= measurements(ind,z1).angle ;
                        traceF2(ind,z1)= measurements(ind,z1).curvature ;
                    end
                end
            end
        end
        angles=nanmedian(traceF,1);
        curves=nanmedian(traceF2,1);
    end
elseif exist([raw_folder original_file '.mat']) ~= 0
    try
        load([raw_folder original_file '.mat']); 
    catch
        disp([raw_folder original_file ' is corrupt.. skipping'])
    end
    if exist('measurements') ~= 0
        traceF=zeros(size(measurements)).*NaN;
        traceF2=zeros(size(measurements)).*NaN;
        for ind=1:size(measurements,1)
            try
%                 z=find([measurements(ind,:).length]>whisker_length & [measurements(ind,:).score]>whisker_score & [measurements(ind,:).follicle_y]<follicle_y_max & [measurements(ind,:).follicle_y]>follicle_y_min & [measurements(ind,:).tip_y]<tip_y_max);
                  face_y = measurements(1, 1).face_y;
                face_x = measurements(1, 1).face_x;
%                 z=find([measurements(ind,:).length]>whisker_length & [measurements(ind,:).score]>whisker_score & [measurements(ind,:).follicle_y]<follicle_y_max & [measurements(ind,:).follicle_y]>follicle_y_min & [measurements(ind,:).tip_y]<tip_y_max);
                z=find([measurements(ind,:).length]>whisker_length & [measurements(ind,:).score]>whisker_score & [measurements(ind,:).follicle_y]<(face_y+100) & [measurements(ind,:).follicle_y]>(face_y-100) & [measurements(ind,:).follicle_x]<(face_x+100));
              
              
                for z1=z
                    if ~isempty( measurements(ind,z1).angle)
                        traceF(ind,z1)= measurements(ind,z1).angle ;
                        traceF2(ind,z1)= measurements(ind,z1).curvature ;
                    end
                end
            end
        end
        angles=nanmedian(traceF,1);
        curves=nanmedian(traceF2,1);
    end
end
   