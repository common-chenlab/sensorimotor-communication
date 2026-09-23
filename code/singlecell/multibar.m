function multibar(A,B,tittit)


% Create grouped bar chart
figure;
hb = bar(A);  
hold on;

% Number of groups and number of bars per group
[numGroups, numBars] = size(A);

% Get the x coordinates of the bars
% The XData is the center of each group and X offset of each bar into the group
for i = 1:numBars
    % X coordinates for bars in this series
    x = hb(i).XEndPoints;  % for MATLAB R2019b or newer
    % Add error bars
    errorbar(x, A(:,i), B(:,i), 'k', 'linestyle', 'none', 'LineWidth', 1);
end

hold off;
xlabel('Group');
ylabel('Value');
title(tittit);
legend('S1', 'S2', 'M1A', 'M1B');