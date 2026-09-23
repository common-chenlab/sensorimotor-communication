function xshift = estimate_flip(filename)
%UCLA STEM Analysis - Peeling/Fitting
%Multi dataset event analysis
%adrcheng@ucla.edu 2010
%
%input is the output from running this function on a different stack or
%   timeseries from the same arm as this one. copy_yshift is either 0 or 1,
%   1 meaning that we will copy the vertical turnaround from the previously
%   corrected images which is defined in input.yshift. Use these two
%   arguments if SNR is low for a certain image and the correction isn't
%   working well


%input file characteristics
myinfo = imfinfo(filename);
%nframes = length(myinfo);
height = myinfo.Height;
width = myinfo.Width;
%raw_data = zeros(height, width, nframes);

info.filename = filename;
raw_data = UCLA_ReadTiff(info);


%%
%nframes = size(raw_data,3);
height = size(raw_data,1);
width = size(raw_data,2);
turnaround_pixel=width/2;

output.height = height*2;
output.width = width/2;

%dividing image into its two halves to be able to use phase correlation
imgl=raw_data(:,1:turnaround_pixel,:);
imgr=raw_data(:,turnaround_pixel+1:end,:);
imgr=flip(imgr,2);

%using phase correlation to find relative shift between halves
if mod(turnaround_pixel,2)==0
    x=-turnaround_pixel/2:turnaround_pixel/2-1;
else
    x=-(turnaround_pixel-1)/2:(turnaround_pixel-1)/2;
end


imgl_mean=100*mean(imgl(:,:,:),3);
imgr_mean=100*mean(imgr(:,:,:),3);
% imgl_mean = imgl_mean(20:60,:);  % use this if non-uniform intensities across image
% imgr_mean = imgr_mean(20:60,:);  % use this if non-uniform intensities across image
IMGL=fft2(imgl_mean);
IMGR=fft2(imgr_mean);
R=(IMGL.*conj(IMGR))./abs(IMGL.*conj(IMGR));
r=fftshift(ifft2(R));
[~,loc]=max(r(:));
[~,col]=ind2sub(size(r),loc);
x_shift=x(col);

%//////////////////////////////// solve problem of not aligned image
% added by Jiasen
if x_shift==0 % relocate xshift if it equals 0
%     ssr=r(:,[col-40:col-11 col+11:col+40]);
%     [~,loca]=max(ssr(:));
%     [~,colu]=ind2sub(size(ssr),loca);
%     if colu<=30
%         column=colu+(col-41);
%     else
%         column=(colu-30)+(col+10);
%     end
    xshift=0;
else
    xshift=x_shift;
end
%////////////////////////////////

end


