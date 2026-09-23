function [r, A, B] = CanonCorrFitAndPredict(Xtrain, Ytrain, Xtest, Ytest)
warning('off','stats:canoncorr:NotFullRank');
lastwarn('')
numPairs = min( size(Xtrain, 2), size(Ytrain, 2) );
[A, B, ~] = canoncorr( Xtrain, Ytrain );
[~, id] = lastwarn;
% Modified by ASB 9/28/23 to allow non-full rank (original version commented below) 
r = zeros(1, numPairs);
for pairIdx = 1:numPairs
    r(pairIdx) = corr( Xtest*A(:,pairIdx), Ytest*B(:,pairIdx) );
end
%{
if ~isempty(id) && strcmp(id, 'stats:canoncorr:NotFullRank')
	r = nan(1, numPairs);
else
	r = zeros(1, numPairs);
	for pairIdx = 1:numPairs
		r(pairIdx) = corr( Xtest*A(:,pairIdx), Ytest*B(:,pairIdx) );
	end
end
%}
warning('on','stats:canoncorr:NotFullRank');
end
