function [fast1, slow1] = balance_idx(fast1, slow1)

a = length(fast1)-length(slow1);
if a > 0
%     fast1 = fast1(randperm(length(fast1)));
%     fast1 = fast1(1:length(slow1));
    if isempty(slow1) == 0
        slow2 = [];
        for i = 1:a
            slow2 =[slow2; randi(length(slow1))];
        end
        slow1 = [slow1; slow2];
    end
elseif a < 0 
%     slow1 = slow1(randperm(length(slow1)));
%     slow1 = slow1(1:length(fast1));
    a = -a;
    if isempty(fast1) == 0 
    fast2 = [];
    for i = 1:a
        fast2=[fast2; randi(length(fast1))];
    end
    fast1 = [fast1; fast2];
    end
end



