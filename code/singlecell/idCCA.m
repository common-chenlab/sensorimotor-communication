function result = idCCA(x2,y)


% x2 = S1id{1};
x = x2(:,1);
% y = CCAweights{1}{1,1}
result = [];
for i = 1:12
    temp = double(x==i);
    temp(temp==0) = NaN;
    y = y/(max(abs(y)));
    result(:,i,1) = abs(temp.*y);
end


x = x2(:,2);
for i = 1:12
    temp = double(x==i);
    temp(temp==0) = NaN;
    y = y/(max(abs(y)));
    result(:,i,2) = abs(temp.*y);
end
