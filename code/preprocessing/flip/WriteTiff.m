function WriteTiff(filename, data)
if ~isa(data, 'uint16')
    error('only support uint16 data type at this time');
end

tiff_file = Tiff(filename, 'w');

[rows, cols, frames] = size(data);

tags.ImageLength = rows;
tags.ImageWidth = cols;
tags.BitsPerSample = 16;
tags.SamplesPerPixel = 1;

tags.Photometric = Tiff.Photometric.MinIsBlack;
tags.SampleFormat = Tiff.SampleFormat.UInt;
tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tags.Compression = Tiff.Compression.LZW;

tags.Software = 'MATLAB';

tags.RowsPerStrip = rows;

for i = 1:frames
    tiff_file.setTag(tags);
    tiff_file.write(data(:,:,i))
    tiff_file.writeDirectory();
end
tiff_file.close();