function keep = filter_border_ROIs_jc(keep, FOV, Coor)

threshold = 0.97;

%% filter objects at the border
for i = 1:length(keep)
    if keep(i) == 1
        a = Coor{i,1};
        a_min = min(rot90(a));
        a_max = max(rot90(a));
        a_range = a_max - a_min;
        if ~isempty(a_range)
            aspect_ratio = a_range(1)/a_range(2);
            
            x_limit = [.02*FOV(2) .98*FOV(2)];
            y_limit = [.02*FOV(1) .98*FOV(1)];
            
%             if aspect_ratio < 0.5
%                 % x
%                 if a_max(1) < x_limit(1)
%                     keep(i) =0;
%                 end
%                 if a_min(1) < x_limit(2)
%                     keep(i) =0;
%                 end
%                 
%             end
%             
%             if aspect_ratio > 4
%                 % y
%                 if a_max(2) < y_limit(1)
%                     keep(i) =0;
%                 end
%                 if a_min(2) < y_limit(2)
%                     keep(i) =0;
%                 end
%             end
             
                % x
                if a_min(1) < x_limit(1)
                    keep(i) =0;
                end
                if a_max(1) > x_limit(2)
                    keep(i) =0;
                end
                
            
            
                % y
                if a_min(2) < y_limit(1)
                    keep(i) =0;
                end
                if a_max(2) > y_limit(2)
                    keep(i) =0;
                end
            
        elseif isempty(a_range)
            keep(i) =0;
        end    
    end
end

%% filter also by eccentricity
for i = 1:length(keep)    
    if keep(i) == 1
        a = Coor{i,1};
        BW = [];
        for j = 1:size(a,1)
            BW(a(j,1),a(j,2)) = 1;
        end
        BW = logical(BW);        
        s = regionprops(BW,'eccentricity');
        s = cell2mat(struct2cell(s));
        s =  min(s);
        if isempty(s) == 0
            if s > threshold                
                keep(i) = 0;
            end
        end
    end
end



    
