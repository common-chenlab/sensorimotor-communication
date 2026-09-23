function normcorre_chen(name)
close all;
gcp;
% fdir1 = 'C:\Users\Chenlab3\Documents\MATLAB\Projects\PIPELINE\NoRMCorre-master\';
% cd(fdir1)

tic; Y = read_file(name); toc; % read the file (optional, you can also pass the path in the function instead of Y)
Y = single(Y);                 % convert to single precision 
T = size(Y,ndims(Y));
%Y = Y - min(Y(:));

%////////// Crop 
temp = zeros(size(Y,1),673,size(Y,3));
for i = 1:size(Y,3)
    temp(:,:,i) = Y(1:end,1:673,i);
end
% temp = zeros(size(Y,1),size(Y,2)-4,size(Y,3));
% for i = 1:size(Y,3)
%     temp(:,:,i) = Y(1:end,1:end-4,i);
% end

Y                 = temp;
clear temp 
% options.big       = false;
% options.overwrite = true;
% res = saveastiff(uint16(Y), [fdir1 '-crop-' name], options)

% %  set parameters (first try out rigid motion correction)
% options_rigid = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2),'bin_width',1,'max_shift',250,'us_fac',20);
% 
% 
% % perform rigid motion correction & save
% tic; [M1,shifts1,template1] = normcorre(Y,options_rigid); toc
% imwrite(uint16(M1(:,:,1)), [fdir1 'rmc_' name])
% 
% for k = 2:size(M1,3)
%     imwrite(uint16(M1(:,:,k)), [fdir1 'rmc_' name], 'writemode', 'append');
% end

% ///// pxq spatial binning of orignial movie
[n1,n2,n3] = size(Y);
Y1         = zeros(round(n1/2),round(n2/2),n3);
p = 2;
q = 2;
for i = 1:n3
  Y1(:,:,i) = imresize(Y(:,:,i), 'scale', [1/p, 1/q]);
end



imagesc(Y1(:,:,10))
options_rigid               = NoRMCorreSetParms('d1',size(Y1,1),'d2',size(Y1,2),'bin_width',15,'max_shift',50,'us_fac',1);
tic; [M0,shifts0,template0] = normcorre(Y1,options_rigid); toc

% imwrite(uint16(M0(:,:,1)), [fdir1 'rmc0_' name])
% for k = 2:size(M0,3)
%     imwrite(uint16(M0(:,:,k)), [fdir1 'rmc0_' name], 'writemode', 'append');
% end

% /// update shift vector for orignial movie
shift2_new = shifts0;
for i = 1:size(Y1,3)
    shift2_new(i).shifts    = [p,q]'.*shifts0(i).shifts;
    shift2_new(i).shifts_up = [p,q]'.*shifts0(i).shifts_up;
    
end
clear Y1
Y2 = apply_shifts(Y,shift2_new,options_rigid);

% now try non-rigid motion correction (also in parallel)
% options_nonrigid = NoRMCorreSetParms('d1',size(Y2,1),'d2',size(Y2,2),'grid_size',[100,250],'mot_uf',8,'bin_width',100,...
%                                      'max_shift',50,'max_dev',50,'us_fac',8, 'min_patch_size', [16 16 16], 'overlap_post',[50,50,16]);
                                 
                                 
options_nonrigid = NoRMCorreSetParms('d1',size(Y2,1),'d2',size(Y2,2),'grid_size',[100,100],'mot_uf',4,'bin_width',60,...
    'max_shift',25,'max_dev',25,'us_fac',4, 'min_patch_size', [16 16 16], 'overlap_post',[25,25,16],'use_parallel',true, ...
    'boundary', 'copy');

    
tic; [M2,shifts2,template2] = normcorre_batch(Y2,options_nonrigid); toc

% options.big       = false;
% options.overwrite = true;
% res = saveastiff(uint16(M2), [fdir1 'nrmc2_' date '-' name], options)
% 
% 
% options_nonrigid = NoRMCorreSetParms('d1',size(Y,1),'d2',size(Y,2),'grid_size',[100,250],'mot_uf',8,'bin_width',3,...
%                                    'max_shift',50,'max_dev',50,'us_fac',8, 'min_patch_size', [16 16 16], 'overlap_post',[50,50,16]);
%       
                                 
% //// Compare to non-scaling version
% tic; [M,shifts,template] = normcorre_batch(Y,options_nonrigid); toc
% 
% options.big       = false;
% options.overwrite = true;
% res = saveastiff(uint16(M), [fdir1 'nrmc_' date '-' name], options)

%% compute metrics
% 
% nnY = quantile(Y(:),0.005);
% mmY = quantile(Y(:),0.995);
% 
% [cY,mY,vY] = motion_metrics(Y,10);
% [cM1,mM1,vM1] = motion_metrics(M1b,10);
% [cM2,mM2,vM2] = motion_metrics(M2,10);
% T = length(cY);
%% plot metrics
% h = figure;
% 
% set(h,'Position', [300 200 1000 1000*0.618])
% 
% ax1 = subplot(2,3,1); imagesc(mY,[nnY,mmY]);  axis equal; axis tight; axis off; title('mean raw data','fontsize',10,'fontweight','bold')
% ax2 = subplot(2,3,2); imagesc(mM1,[nnY,mmY]);  axis equal; axis tight; axis off; title('mean rigid corrected','fontsize',10,'fontweight','bold')
% ax3 = subplot(2,3,3); imagesc(mM2,[nnY,mmY]); axis equal; axis tight; axis off; title('mean non-rigid corrected','fontsize',10,'fontweight','bold')
% subplot(2,3,4); plot(1:T,cY,1:T,cM1,1:T,cM2); legend('raw data','rigid','non-rigid'); title('correlation coefficients','fontsize',10,'fontweight','bold')
% subplot(2,3,5); scatter(cY,cM1); hold on; plot([0.9*min(cY),1.05*max(cM1)],[0.9*min(cY),1.05*max(cM1)],'--r'); 
% xlabel('raw data','fontsize',14,'fontweight','bold'); ylabel('rigid corrected','fontsize',10,'fontweight','bold');
% subplot(2,3,6); scatter(cY,cM2); hold on; plot([0.9*min(cY),1.05*max(cM1)],[0.9*min(cY),1.05*max(cM1)],'--r');
% xlabel('raw data','fontsize',14,'fontweight','bold'); ylabel('non-rigid corrected','fontsize',10,'fontweight','bold');
% linkaxes([ax1,ax2,ax3],'xy')
% 
% 
% %% plot shifts        
% 
% shifts_r = horzcat(shifts1(:).shifts)';
% shifts_nr = cat(ndims(shifts2(1).shifts)+1,shifts2(:).shifts);
% shifts_nr = reshape(shifts_nr,[],ndims(Y)-1,T);
% shifts_x = squeeze(shifts_nr(:,1,:))';
% shifts_y = squeeze(shifts_nr(:,2,:))';
% 
% patch_id = 1:size(shifts_x,2);
% str = strtrim(cellstr(int2str(patch_id.')));
% str = cellfun(@(x) ['patch # ',x],str,'un',0);
% 
% h = figure;
% 
% set(h,'Position', [300 200 1000 1000*0.618])
%     ax1 = subplot(311); plot(1:T,cY,1:T,cM1,1:T,cM2); legend('raw data','rigid','non-rigid'); title('correlation coefficients','fontsize',14,'fontweight','bold')
%             set(gca,'Xtick',[])
%     ax2 = subplot(312); plot(shifts_x); hold on; plot(shifts_r(:,1),'--k','linewidth',2); title('displacements along x','fontsize',14,'fontweight','bold')
%             set(gca,'Xtick',[])
%     ax3 = subplot(313); plot(shifts_y); hold on; plot(shifts_r(:,2),'--k','linewidth',2); title('displacements along y','fontsize',14,'fontweight','bold')
%             xlabel('timestep','fontsize',14,'fontweight','bold')
%     linkaxes([ax1,ax2,ax3],'x')
% 
% %% plot a movie with the results
% 
% figure;
% for t = 1:1:T
%     subplot(121);imagesc(Y(:,:,t),[nnY,mmY]); xlabel('raw data','fontsize',14,'fontweight','bold'); axis equal; axis tight;
%     title(sprintf('Frame %i out of %i',t,T),'fontweight','bold','fontsize',14); colormap('bone')
%     subplot(122);imagesc(M2(:,:,t),[nnY,mmY]); xlabel('non-rigid corrected','fontsize',14,'fontweight','bold'); axis equal; axis tight;
%     title(sprintf('Frame %i out of %i',t,T),'fontweight','bold','fontsize',14); colormap('bone')
%     set(gca,'XTick',[],'YTick',[]);
%     drawnow;
%     pause(0.02);
% end


tiff_info.directory = ['\'];
tiff_info.filename = ['M2_' name];
tiff_info.bitspersample = 16;
tiff_info.floatingpoint = false;
tiff_info.nframes = size(M2,3);

UCLA_WriteTiff(uint16(M2), tiff_info);

avgimg = mean(M2, 3);
avgimg = 65536*(avgimg-min(avgimg(:)))/(max(avgimg(:))-min(avgimg(:)));
imwrite(uint16(avgimg), ['Avg_' name]);
