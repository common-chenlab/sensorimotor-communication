function touch_vector = get_touch(raw_folder, original_file, radius)

touch_vector = [];

try
    
    load([raw_folder original_file]);
    if exist([raw_folder original_file '_nofilter.mat'])  == 2
         load([raw_folder original_file '_nofilter.mat']);
    end
    
    touch_vector(1,1:size(whiskers,2)) = 0;
    
    %%
    for i=1:length(object)
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
                    for k = -radius:1:radius
                        for l = -radius:1:radius
                            field_temp = [field_temp; temp(:,1)+k, temp(:,2)+l];
                        end
                    end
                    [c2, ia2, ib2] =  intersect(field_temp, objpos, 'rows');
                    if isempty(c2) == 0
                        touch_vector(fid) = 1;
                    end
                end
            end
        end
    end
catch
    
end
