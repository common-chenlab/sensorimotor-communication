function data = readTiff(filename)
%tStart = tic;
t = Tiff(filename, 'r');
height = t.getTag(Tiff.TagID.ImageLength);
width = t.getTag(Tiff.TagID.ImageWidth);

nframes = 1;
while ~t.lastDirectory
    try
        t.nextDirectory;
    catch
        break;
    end
    nframes = nframes + 1;
end

data = zeros(height, width, nframes, 'uint16');
t.setDirectory(1);
for i = 1:nframes
    data(:, :, i) = t.read();
    if i < nframes
        t.nextDirectory;
    end
end
t.close();

%tEnd = toc(tStart);
%disp(['reading tiff file took: ', num2str(tEnd), 's'])