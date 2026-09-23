function [data_out, xshift] = fixOffsetAndDewarp(data_in, doDewarp)

avg = mean(data_in, 3);
imgl = avg(1:2:end, :);
imgr = avg(2:2:end, :);

tf = imregcorr(imgr, imgl, "translation");
tf.T(3, 2) = 0;
xshift = tf.T(3, 1);

out_view = affineOutputView(size(imgl), tf, "BoundsStyle", "SameAsInput");
clear avg imgl imgr;

imgl_new = data_in(1:2:end, :, :);
imgr = data_in(2:2:end, :, :);
imgr_new = imwarp(imgr, tf, "OutputView", out_view);

data_flipped = zeros(size(data_in), 'uint16');
for i= 1:size(data_in, 1)
    if mod(i, 2) == 1
        data_flipped(i, :, :) = imgl_new((i+1)/2, :, :);
    else
        data_flipped(i, :, :) = imgr_new(i/2, :, :);
    end
end
clear imgr_new imgl_new;

if doDewarp
    [xmap, ymap] = makeMaps2(size(data_in, 1), size(data_in, 2));
    data_out = zeros(size(data_in));
    for i = 1:size(data_in, 3)
        data_out(:, :, i) = interp2(data_flipped(:, :, i), xmap, ymap, 'nearest');
    end
else
    data_out = data_flipped;
end