function [gaussFilt, gaussSigma] = MakeGaussFilt( sample_rate, gaussWidth, gaussMean, gaussSigma, varargin )
%Make a normalized Gaussian filter for smoothing data
%INPUTS
% gaussWidth = width, in seconds, of full Gaussian filter kernel
% gaussMean = mean of the Gaussian, in seconds
% gaussSigma = spread of the Gaussian, in seconds
% sample_rate, in Hertz
% show = show the resulting filter kernel (or not)
%OUTPUTS
% gaussFilt = gaussian filter for use in conv function
IP = inputParser;
addRequired( IP, 'sample_rate', @isnumeric )
addRequired( IP, 'gaussWidth', @isnumeric )
addRequired( IP, 'gaussMean', @isnumeric )
addRequired( IP, 'gaussSigma', @isnumeric )
addParameter( IP, 'cutoff', NaN, @isnumeric )
addParameter( IP, 'show', false, @islogical )
parse( IP, sample_rate, gaussWidth, gaussMean, gaussSigma, varargin{:} ); % mouse, exptDate,
cutoffSet = IP.Results.cutoff;
show = IP.Results.show;

gaussWidthFrame = round(gaussWidth*sample_rate); 
if rem(gaussWidthFrame,2) == 0, gaussWidthFrame = gaussWidthFrame + 1; end % enforce oddness
gaussMeanFrame = round(gaussMean*sample_rate); 
%gaussSigma = 1/(2*pi*lpFreq)
if ~isnan(cutoffSet)
    gaussSigma = 1/(2*pi*cutoffSet);
    fprintf('\nCutoff set to %2.3f Hz, setting sigma to %2.3f s',cutoffSet, gaussSigma);
end
gaussSigmaFrame = gaussSigma*sample_rate; %round(gaussSigma*sample_rate); 
if gaussSigmaFrame == 0, error('Standard deviation is 0 frames!'); end

tGauss = linspace(-gaussWidthFrame/2, gaussWidthFrame/2, gaussWidthFrame);  
gaussFilt = exp(-(tGauss-gaussMeanFrame).^2/(2*gaussSigmaFrame^2));  %exp(-tGauss.^2/(2*gaussSigmaFrame^2));
gaussFilt = double(gaussFilt/sum(gaussFilt)); % normalize
if show
    figure('Units','normalized','OuterPosition',[0,0,1,1]); 
    plot( tGauss/sample_rate, gaussFilt ); axis tight; 
    xlabel('Time (s)'); % plot( tGauss, gaussFilt )
    title( sprintf('Width = %2.2f sec, mean, = %2.2f, sigma = %2.2f sec, frame rate = %2.2f Hz, cutoff = %2.2f Hz', gaussWidth, gaussMean, gaussSigma, sample_rate, 1/(2*pi*gaussSigma) ) );
end
end

