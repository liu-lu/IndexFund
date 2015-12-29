function y = RoundHolding( m, y, cfg, di )
% 零股处理

y( isnan(y) ) = 0;
ops = m.ops(:,di);

s = m.hs300weights(:,di-1);
s(s>0) = s(s>0) / sum( s(s>0) );
s(isnan(s)) = 0;
s = cfg.scale * s;
y = y + s;
y( y<0 ) = 0;
y(1) = 0;

y = floor(y./ops/100) *100 .* ops; 
y( y == 0 ) = nan;
y(1) = -sum( y(y>0) ); %-round( sum( y(y>0) ) / ops(1) / 300 ) * 300 * ops(1);

end
