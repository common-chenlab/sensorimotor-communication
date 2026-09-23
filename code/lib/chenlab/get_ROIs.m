function fov = get_ROIs(data_struct, fov, gamma_value, crop_size)
if nargin < 3, gamma_value = 0.2; end
if isfield(data_struct, 'ROIs_REF')
    anm = extractBefore(fov.name,'-');
    session_num = extractBefore(extractAfter(fov.name, '-'), '-');
    fov.n_CNMF = numel(data_struct.ROIs); % # of automated ROIs
    fov.n_ROI = numel(data_struct.ROIs_REF); % # of curated ROIs
    fov.cell_ID = data_struct.cellid_REF;

    % which ROIs were retained from CNMF, modified or drawn manually?
    %{
    [cellID_int, roi_int_auto, roi_int_ref] = intersect(data_struct.cellid, data_struct.cellid_REF, 'stable');
    auto_size = cellfun(@length, data_struct.ROIs);
    ref_size = cellfun(@length, data_struct.ROIs_REF);
    diff([auto_size(roi_int_auto)'; ref_size(roi_int_ref)'], 1)
    %}
    [~,roi_drawn] = setdiff(data_struct.cellid_REF, data_struct.cellid); % drawn manually
    roi_drawn = sort(roi_drawn)';
    [~,roi_cnmf] = setdiff(1:fov.n_ROI, roi_drawn);
    roi_cnmf = roi_cnmf';
    fov.roi_auto = roi_cnmf;
    fov.roi_drawn = roi_drawn;

    % Did any ROI names repeat?
    [name_uniq, ~, roi_uniq] = unique(fov.cell_ID);
    if numel(name_uniq) ~= fov.n_ROI
        fprintf('\nRenaming redundantly-named ROIs')
        for roi_repeat = find(histcounts(roi_uniq, 1:fov.n_ROI) > 1)
            temp_roi = find(roi_uniq == roi_repeat)';
            for R = 2:numel(temp_roi)
                fov.cell_ID{temp_roi(R)} = strcat(fov.cell_ID{roi_repeat}, sprintf('_%i',R) ); % .name
            end
        end
    end
    %flip_transpose = @(x)(flip(transpose(x),2));
    %data_struct.ROIs = cellfun(flip_transpose, data_struct.ROIs, 'UniformOutput', false); % make CNMF ROIs compatible with poly2mask
    fov.ROI = repmat(struct('fov',str2double(extractAfter(fov.fov_name,'A')), 'name',[], 'cent',[NaN,NaN], 'ecc',[], 'edge',[], 'im',[], 'ind',[], 'int_mean',NaN, 'length',NaN, 'orient',NaN, 'solid',NaN, 'mch_ratio',NaN), 1, fov.n_ROI);
    for roi = 1:fov.n_ROI
        fov.ROI(roi).name = data_struct.cellid_REF{roi};
        % Get mask properties
        temp_mask = poly2mask(data_struct.ROIs_REF{roi}(:,2), data_struct.ROIs_REF{roi}(:,1), fov.n_pix(1), fov.n_pix(2)); % temp_poly(roi).createMask;%imshow(temp_poly.createMask);
        %imshow(temp_mask)
        %{
        roi_match = roi_int_auto(find(roi_int_ref == roi)); % index of matching CNMF ROI
        if ~isempty(roi_match)
            temp_match_mask = poly2mask(data_struct.ROIs{roi_match}(:,2), data_struct.ROIs{roi_match}(:,1), fov.n_pix(1), fov.n_pix(2));
        end
        %}
        temp_props = regionprops( temp_mask, 'centroid', 'Area', 'solidity', 'eccentricity', 'MajorAxisLength', 'orientation', 'pixelidxlist' ); % , 'pixellist'
        fov.ROI(roi).area = temp_props.Area;
        fov.ROI(roi).cent = temp_props.Centroid;
        fov.ROI(roi).ecc = temp_props.Eccentricity;
        fov.ROI(roi).ind = temp_props.PixelIdxList;
        fov.ROI(roi).length = temp_props.MajorAxisLength;
        fov.ROI(roi).orient = temp_props.Orientation;
        fov.ROI(roi).solid = temp_props.Solidity;
        fov.ROI(roi).edge = bwboundaries(temp_mask);
        fov.ROI(roi).edge = fov.ROI(roi).edge{1};
        % Get intensity-dependent properties
        if ~isempty(fov.mean)
            temp_props = regionprops( temp_mask, fov.mean, 'centroid', 'MeanIntensity' );
            fov.ROI(roi).cent = temp_props.Centroid;
            fov.ROI(roi).int_mean = temp_props.MeanIntensity; % fov_data.b_dp(roi};
            %text( fov.ROI(roi).Centroid(1), fov.ROI(roi).Centroid(2), num2str(roi), 'HorizontalAlignment','center')
            %plot(fov.ROI(roi).edge(:,2), fov.ROI(roi).edge(:,1), '--');
        end
        % get mCherry score
        if isfield(data_struct, 'celltype_REF')
            try
                fov.ROI(roi).mch_ratio = data_struct.celltype_REF{roi};
            catch
                fprintf('\nIssues with mch_ratio!');
            end
        end
    end

    % Identify each ROI's the nearest neighbor ROI and their centroid-centroid distance in microns
    cent_mat = fov.um_per_pixel.*vertcat(fov.ROI.cent); % convert to um, to account for 
    for roi = 1:fov.n_ROI
        temp_dist = pdist2(cent_mat, fov.ROI(roi).cent);
        temp_dist(roi) = NaN;
        [fov.ROI(roi).nearest_dist, fov.ROI(roi).nearest_neighbor] = min(temp_dist);
    end

    % Save cropped, annotated images of each cell, if they don't already exist
    if ~isempty(fov.diff_max) %false %~
        [roi_png, roi_png_path] = FileFinder(fov.fig_dir, 'type','png');
        n_png = numel(roi_png);
        if n_png ~= fov.n_ROI %false %
            % If there are too many png files delete them all and start fresh
            if n_png > 0
                for p = 1:n_png, delete(roi_png_path{p}); end
            end
            fov.ROI_label = zeros(fov.n_pix);
            for roi = 1:fov.n_ROI
                fov.ROI_label(fov.ROI(roi).ind) = roi;
                close all;
                imshow( imadjust(fov.diff_max,[],[],gamma_value), []); hold on;
                for r = setdiff(1:fov.n_ROI, roi)
                    %text( fov.ROI(roi).cent(1), fov.ROI(roi).cent(2), num2str(roi), 'HorizontalAlignment','center')
                    plot(fov.ROI(r).edge(:,2), fov.ROI(r).edge(:,1), 'c--');
                end
                plot(fov.ROI(roi).edge(:,2), fov.ROI(roi).edge(:,1), 'c-.');
                xLim = fov.ROI(roi).cent(1)+crop_size(1)*[-1,1];
                xLim(xLim<0) = 0; xLim(xLim>fov.n_pix(2)) = fov.n_pix(2);
                yLim = fov.ROI(roi).cent(2)+crop_size(2)*[-1,1];
                yLim(yLim<0) = 0; yLim(yLim>fov.n_pix(1)) = fov.n_pix(1);
                xlim(xLim); ylim(yLim);
                % Save the figure
                roi_fig_path = sprintf('%s%s-%s-%s-ROI%03i.png', fov.fig_dir, anm, session_num, fov.fov_name, roi);
                fprintf('\nSaving %s', roi_fig_path)
                exportgraphics(gca, roi_fig_path);
                %pause
            end
            [~, roi_png_path] = FileFinder(fov.fig_dir, 'type','png');
        end
        close all;

        % Load the images
        if n_png == fov.n_ROI
            for roi = 1:fov.n_ROI
                %fprintf('\nLoading %s', roi_png_path{roi})
                fov.ROI(roi).im = imread(roi_png_path{roi});
            end
        end
    end
end
end