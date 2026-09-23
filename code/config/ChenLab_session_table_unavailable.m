function animal_table = ChenLab_session_table_unavailable(varargin) %#ok<STOUT>
% Placeholder for the lab's session-tracking table (`ChenLab2Ptable`).
%
%   The lab version crawls the acquisition servers and the lab's session spreadsheets to
%   report how far each session has been processed. It was a bookkeeping aid, not part of
%   the analysis, so it is not deposited (author decision, 2026-09-17).
%
%   The session list the paper actually uses is in the deposited data, as the `control`
%   variable of Analysis/summary.mat (44 control sessions; `c21` holds the 32 C21 sessions,
%   which no figure uses).

error('sm:noSessionTable', ['The lab session table (ChenLab2Ptable) is not part of this ' ...
    'deposit: it required the lab acquisition servers and session spreadsheets.\n' ...
    'Use the session list in %sAnalysis/summary.mat (variable `control`) instead.'], smroot());
end
