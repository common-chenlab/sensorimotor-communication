function object_vector = get_object(raw_folder, original_file)

object_vector = [];

try
    
    load([raw_folder original_file]);
    if exist([raw_folder original_file '_nofilter.mat'])  == 2
         load([raw_folder original_file '_nofilter.mat']);
    end
        
    %%
    for i=1:length(object)
        fid = object(i).fid;
        if i <= size(measurements, 2)
            if isempty(object(i).pointsX) == 0
                objpos = [object(i).pointsX, object(i).pointsY];
                object_vector = [object_vector; nanmean(objpos,1)];
            else
                object_vector = [object_vector; NaN,NaN];
            end
        end
    end
catch
    
end
