function y = Drawdown(x)

last_drawdown = 0;
last_s = 1;
last_e = 1;

cum = cumsum(x);

for i = 2:length(x)
    dd = cum(i) - max(cum(1:i));
    if dd < last_drawdown
        last_drawdown  = dd;
        last_e = i;
        last_s = find(cum(1:i) == max(cum(1:i)),1,'last');
    end
end

y = [last_drawdown last_s last_e];
