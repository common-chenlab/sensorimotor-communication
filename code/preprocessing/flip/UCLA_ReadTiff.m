function [ data, output] = UCLA_ReadTiff( info )
%UCLA_ReadTiff Reads in TIFF stacks of various types and gives disk speed
%   Fill in info.filename with filename to read in tiff
    %{
    hdf5 = 0;
    if hdf5
        tic;
        [mydir, myfile, myext] = fileparts(info.filename)
        data = h5read([mydir, myfile, 'h5'],'/data');
        data = permute(data,[2 1 3]);
        output = 1;
        elapsed = toc;
        fprintf('Finished reading file in %f secs\n',elapsed);
        %assumes 1 byte per pix for now
        fprintf('Read speed %f MB/s\n',...
        output.height*output.width*output.nframes/elapsed/10^6);
        return;
    end
    

    precopy = 0;
	if precopy
		%precopy
		fprintf('Copying to RAM file to avoid network seek\n');
		ramfile = ['D:\\',info.filename(3:end)];
		[path,name,ext] = fileparts(ramfile);
		mkdir(path);
		copyfile(info.filename, ramfile);
		info.filename = ramfile
    end

    if 0
        %METHOD ONLY FOR 8/16-BIT!!
		%precopy
		fprintf('Copying to RAM file to avoid network seek\n');
		ramfile = ['D:\\',info.filename(3:end)];
		[path,name,ext] = fileparts(ramfile);
		mkdir(path);
		copyfile(info.filename, ramfile);
		info.filename = ramfile
		tic;
        savedir = pwd;
        [mydir, myfile, myext] = fileparts(info.filename)
        chdir(mydir);
        fprintf('Trying read TIFF using all-matlab low level io\n')
        fprintf('Previous libTIFF mex choked on external call overhead\n')
        tf = tiffread([myfile myext]);
        output.height = tf(1).height;
        output.width = tf(1).width;
        output.nframes = length(tf);
        elapsed = toc;
        fprintf('Finished reading file in %f secs\n',elapsed);
        %assumes 1 byte per pix for now
        fprintf('Read speed %f MB/s\n',...
        tf(1).width*tf(1).height*length(tf)/elapsed/10^6);
        chdir(savedir)
        
        data = zeros(output.height, output.width, output.nframes);
        for i=1:length(tf)
            data(:,:,i) = tf(i).data(:,:);
		end
		
		%cleanup
		rmdir(fileparts(path),'s')
		return
	end
	

    if 0
        %METHOD ONLY FOR 8/16-BIT!!
        tic;
        savedir = pwd;
        [mydir, myfile, myext] = fileparts(info.filename)
        chdir(mydir);
        fprintf('Trying read TIFF using all-matlab low level io\n')
        fprintf('Previous libTIFF mex choked on external call overhead\n')
        tf = tiffread([myfile myext]);
        output.height = tf(1).height;
        output.width = tf(1).width;
        output.nframes = length(tf);
        elapsed = toc;
        fprintf('Finished reading file in %f secs\n',elapsed);
        %assumes 1 byte per pix for now
        fprintf('Read speed %f MB/s\n',...
        tf(1).width*tf(1).height*length(tf)/elapsed/10^6);
        chdir(savedir)
        
        data = zeros(output.height, output.width, output.nframes);
        for i=1:length(tf)
            data(:,:,i) = tf(i).data(:,:);
        end
        
        
        return
    end
    
	if 0
        %METHOD OK FOR 32 BIT!!
		[data, output] = UCLA_ReadTiffFast( info );
		return
	end
	
	if 0
		[data, output] = UCLA_ReadTiffFastNoCache( info );
		return
	end
	%}
    tic;
    
    %info.filename
    get_channel = 1;
    iscolor = false;
        
	%input file characteristics
	myinfo = imfinfo(info.filename);
	output.nframes = length(myinfo);
    %nframes = 10;
	output.height = myinfo(1).Height;
	output.width = myinfo(1).Width;
    
 	data = zeros(output.height, output.width, output.nframes,'uint16');
%     data = zeros(output.height, output.width, output.nframes,'double');
	
	%read in file into memory using imread
    %otherwise, use the TIFF object/LIBTIFF
    do_imread = 0;
    if (do_imread)
        
        for j=1:output.nframes
%             fprintf('Frame %d of %d\r',j,output.nframes);
            if(~iscolor)
                data(:,:,j) = imread(info.filename,'Index',j);
            else
                temp = imread(filetemp,'Index',j);
                data(:,:,j) = temp(:,:,get_channel);
            end
        end
        
    else
        %open Tiff file
        t = Tiff(info.filename,'r');
        temp_channel = zeros(output.height,output.width,3);
        %offsets = t.getTag('SubIFD');
        for j=1:output.nframes
            if(mod(j,10)==0)
%                 fprintf('Frame %d of %d\r',j,output.nframes);
            end
            %t.setDirectory(offsets(n));
            t.setDirectory(j);
            temp_channel =  t.read();
            data(:,:,j) = temp_channel(:,:,get_channel);
        end
        t.close();
        
    end

    elapsed = toc;
    
    %{
    if precopy
		%cleanup
		rmdir(fileparts(path),'s')
    end
    %}
    
    %fprintf('Finished reading file in %f secs\n',elapsed);
    %assumes 1 byte per pix for now
    %fprintf('Read speed %f MB/s\n',  output.height*output.width*output.nframes/elapsed/10^6);
end

