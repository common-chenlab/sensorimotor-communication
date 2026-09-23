% ParforProgressbar   Progress monitor for `parfor` loops
%    
%    <strong>MATLAB 2025+ Version</strong>
%    Refactored to use parallel.pool.DataQueue instead of deprecated UDP/Timers.
%
%    <strong>Usage:</strong>
%    numIterations = 10000;
%    ppm = ParforProgressbar(numIterations);
%
%    parfor i = 1:numIterations
%       % do some parallel computation
%       pause(0.001);
%       % increment counter to track progress
%       ppm.increment();
%    end
%
%    % Clean up
%    delete(ppm);
%
%    <strong>Options:</strong>
%    ppm = ParforProgressbar(N, 'showWorkerProgress', true) 
%    ppm = ParforProgressbar(N, 'title', 'My Job')
%    ppm = ParforProgressbar(N, 'parpool', 'local')
%
%    Requires: <a href="https://de.mathworks.com/matlabcentral/fileexchange/6922-progressbar">progressbar</a> 
%    (If 'progressbar' is missing, it falls back to standard 'waitbar').
classdef ParforProgressbar < handle
    
    properties (GetAccess = private, SetAccess = private)
        % Communication
        DataQueue       % The parallel.pool.DataQueue object
        
        % Configuration
        TotalIterations % Total iterations expected
        StepSize        % Reporting interval
        ShowWorkers     % Boolean: show individual worker bars
        Title           % Title string
        
        % State (Client Side)
        ProgressTotal   % Integer: Total completed iterations
        WorkerTracker   % Map or Array to track progress per worker
        
        % State (Worker Side)
        IterCount       % Counter for the specific worker
        WorkerID        % Cached ID of the current worker
        
        % Visuals
        UseExternalBar  % Boolean: True if 'progressbar.m' exists
        WaitbarHandle   % Fallback handle if using waitbar
    end
    
    methods
        function obj = ParforProgressbar(numIterations, varargin)
            % Parse Inputs
            p = inputParser;
            validNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
            addRequired(p, 'numIterations', validNum);
            addParameter(p, 'showWorkerProgress', false, @isscalar);
            addParameter(p, 'progressBarUpdatePeriod', 1.0, validNum); % Kept for API compat, but unused (event-driven now)
            addParameter(p, 'title', 'Progress', @ischar);
            addParameter(p, 'parpool', '', @(x) ischar(x) || iscell(x));
            
            parse(p, numIterations, varargin{:});
            
            obj.TotalIterations = p.Results.numIterations;
            obj.ShowWorkers = p.Results.showWorkerProgress;
            obj.Title = p.Results.title;
            
            % Handle Parallel Pool
            poolArgs = p.Results.parpool;
            poolObj = gcp('nocreate');
            if isempty(poolObj)
                if isempty(poolArgs)
                    poolObj = parpool; 
                elseif ischar(poolArgs)
                    poolObj = parpool(poolArgs);
                elseif iscell(poolArgs)
                    poolObj = parpool(poolArgs{:});
                end
            end
            
            numWorkers = poolObj.NumWorkers;
            
            % Initialize DataQueue
            % This is the modern replacement for UDP.
            obj.DataQueue = parallel.pool.DataQueue;
            afterEach(obj.DataQueue, @obj.updateDisplay);
            
            % Calculate Step Size
            % Avoid sending data every single iteration to reduce overhead.
            % We aim for roughly 100 updates per worker over the life of the job.
            if (obj.TotalIterations / numWorkers) > 1000
                obj.StepSize = floor(obj.TotalIterations / numWorkers / 100);
            else
                obj.StepSize = 1;
            end
            
            % Initialize State
            obj.ProgressTotal = 0;
            if obj.ShowWorkers
                % Map worker ID (1..N) to iteration count
                obj.WorkerTracker = zeros(numWorkers, 1);
            end
            
            % Initialize Visuals
            % Check if the external 'progressbar' function exists
            if ~isempty(which('progressbar'))
                obj.UseExternalBar = true;
                if obj.ShowWorkers
                    % Setup multi-bar labels
                    titles = cell(numWorkers + 1, 1);
                    titles{1} = obj.Title;
                    for i = 1:numWorkers
                        titles{i+1} = sprintf('Worker %d', i);
                    end
                    progressbar(titles{:});
                else
                    progressbar(obj.Title);
                end
            else
                % Fallback to standard waitbar
                obj.UseExternalBar = false;
                obj.WaitbarHandle = waitbar(0, '0%', 'Name', obj.Title);
            end
            
            % Initialize Worker-side transient properties
            obj.IterCount = 0;
        end
        
        function increment(obj)
            % This method runs on the WORKER
            
            % Identify current task if not cached
            if isempty(obj.WorkerID)
                t = getCurrentTask();
                if ~isempty(t)
                    obj.WorkerID = t.ID;
                else
                    obj.WorkerID = 1; % Fallback for serial execution
                end
            end
            
            obj.IterCount = obj.IterCount + 1;
            
            % Check if we should send an update to the client
            if mod(obj.IterCount, obj.StepSize) == 0
                % Send payload: [WorkerID, IterationsSinceLastSend]
                send(obj.DataQueue, [obj.WorkerID, obj.StepSize]);
            end
        end
        
        function delete(obj)
            % Destructor
            if obj.UseExternalBar
                % Close external progressbar (set to 100%)
                % progressbar(1); % Optional: force completion
            else
                if ~isempty(obj.WaitbarHandle) && isvalid(obj.WaitbarHandle)
                    delete(obj.WaitbarHandle);
                end
            end
        end
    end
    
    methods (Access = private)
        function updateDisplay(obj, data)
            % This runs on the CLIENT whenever 'send' is called
            
            workerID = data(1);
            countDelta = data(2);
            
            % Update Globals
            obj.ProgressTotal = obj.ProgressTotal + countDelta;
            overallFraction = obj.ProgressTotal / obj.TotalIterations;
            
            % Update Worker Specifics
            if obj.ShowWorkers && ~isempty(obj.WorkerTracker)
                obj.WorkerTracker(workerID) = obj.WorkerTracker(workerID) + countDelta;
            end
            
            % Draw
            if obj.UseExternalBar
                if obj.ShowWorkers
                    % Calculate individual worker fractions
                    % We assume even distribution for estimation: Total / NumWorkers
                    estWorkPerWorker = obj.TotalIterations / length(obj.WorkerTracker);
                    workerFractions = obj.WorkerTracker / estWorkPerWorker;
                    
                    % Cap at 1.0 to prevent visual bugs
                    workerFractions(workerFractions > 1) = 1;
                    
                    % Convert to cell for varargin
                    fracs = [overallFraction; workerFractions];
                    fracCell = num2cell(fracs);
                    progressbar(fracCell{:});
                else
                    progressbar(overallFraction);
                end
            else
                % Fallback Waitbar
                if isvalid(obj.WaitbarHandle)
                    waitbar(overallFraction, obj.WaitbarHandle, ...
                        sprintf('%.1f%%', overallFraction * 100));
                end
            end
        end
    end
end