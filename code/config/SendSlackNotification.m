function SendSlackNotification(varargin)
% SENDSLACKNOTIFICATION  No-op stand-in for the lab's Slack progress notifier.
%
%   Several pipeline scripts ping a Slack channel when a long job finishes. The lab
%   version posts to an incoming-webhook URL, which is a credential and is redacted from
%   the copies in this repository (see tools/build_repo.py). This stub keeps those calls
%   harmless so the scripts can be read and run without the lab's Slack workspace.
end
