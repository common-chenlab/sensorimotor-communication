function [chunk_lims, n_chunk, chunk_length] = MakeChunkLims(firstScan, lastScan, totScan, varargin)
IP = inputParser;
addRequired( IP, 'firstScan', @isnumeric )
addRequired( IP, 'lastScan', @isnumeric )
addOptional( IP, 'totScan', lastScan, @isnumeric )
addParameter( IP, 'N',NaN, @isnumeric ) % set # of chunks
addParameter( IP, 'size',NaN, @isnumeric ) % or set chunk size, setting N to non-nan will override this
addParameter( IP, 'partial',0, @isnumeric ) % chunks must contain at least this fraction of the full chunk to be kept
parse( IP, firstScan, lastScan, totScan, varargin{:} );
totScan = IP.Results.totScan;
if totScan < lastScan, lastScan = totScan; warning('totScan < lastScan'); end
partial = IP.Results.partial;

% Determine chunk size either directly or as needed to get desired # of bins
if ~isnan(IP.Results.N)
    n_chunk = IP.Results.N;
    chunk_ratio = (lastScan-firstScan+1)/n_chunk; % # of integers between first and last scan, inclusive / # of chunks selected
    if chunk_ratio < 1, error('chunk_ratio < 1'); end
    chunk_lims = round((linspace(firstScan-1,lastScan,n_chunk+1)+1))';
    chunk_lims = [chunk_lims, circshift(round(chunk_lims), -1)-1];
    chunk_lims(end,:) = [];
    chunk_length = diff(chunk_lims,1,2)+1;
elseif ~isnan(IP.Results.size)
    chunkSize = IP.Results.size;
    chunk_lims = (firstScan:chunkSize:lastScan)';
    chunk_lims(:,2) = chunk_lims(:,1) + chunkSize - 1;
    if chunk_lims(end) > lastScan, chunk_lims(end) = lastScan; end
    chunk_lims(chunk_lims(:,1) > totScan, :) = [];
    n_chunk = size(chunk_lims, 1);
    chunk_length = diff(chunk_lims,1,2)+1;
    % suppress partial chunks  (optional)
    if chunk_length(end)/chunkSize < partial
        chunk_lims(end,:) = [];
        chunk_length(end) = [];
        n_chunk = n_chunk-1;
    end
else
    error('N or size flag must be set')
end
end