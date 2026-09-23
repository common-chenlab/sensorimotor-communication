function result = get_touch_radius(raw_folder, original_file)

result(1,1:4) = 0;

try
    
    load([raw_folder original_file]);
    if exist([raw_folder original_file '_nofilter.mat'])  == 2
         load([raw_folder original_file '_nofilter.mat']);
    end
    
    touch_vector(1,1:size(whiskers,2)) = 0;
    
    
    %% determine optimal radius    
    for asd = 3:3:12
        for i= 1800:2:2000
            fid = object(i).fid;
            if i <= size(measurements, 2)
                if isempty(object(i).pointsX) == 0
                    objpos = [object(i).pointsX, object(i).pointsY];
                    temp = [];
                    for j = 1:size(measurements,1)
                        temp_x = round(measurements(j, fid).tip_x);
                        temp_y = round(measurements(j, fid).tip_y);
                        temp = [temp; temp_y, temp_x];
                    end
                    if isempty(temp) == 0
                        field_temp = [];
                        for k = -asd:1:asd
                            for l = -asd:1:asd
                                field_temp = [field_temp; temp(:,1)+k, temp(:,2)+l];
                            end
                        end
                        [c2, ia2, ib2] =  intersect(field_temp, objpos, 'rows');
                        if isempty(c2) == 0
                            result(asd/3) = result(asd/3) + 1;                       
                        end
                    end
                end
            end
        end
    end
    
    
    
   
catch
    
end
