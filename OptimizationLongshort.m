function [y,res] = OptimizationLongshort( x )
%优化框架

y = nan( size( x.valid ) );
n1 = x.n1;
nind1 = x.nind1; nind2 = x.nind2;

% w = [ weight(n1*1); changeweight(n1*1); tol(1*1) ]

% prob.a
% x.beta为股票的beta值
% x.ind：如果该股票属于该ind，则相应的值为1

prob.a = sparse( [eye(n1), -eye(n1), zeros(n1,1);
    ones(1,n1), zeros(1,n1+1);
    x.betas', zeros(1,n1+1);
    %x.ind2, zeros(nind2,n1+1);
    x.ind1, zeros(nind1,n1+1)] );

% prob.blc/buc (risk:'size'; 'value') 'mmt'%%
%今天的权重+turnover和前一天的权重一致
%多头和空头总和为零（目前假设允许做空）
%beta的总偏离控制在+-1%内
%每个行业的偏离（即在该行业上的资金量）控制在+-indrisk内
%indrisk和整个行业在股指中的权重有关
prob.blc = [ x.x; 0; -x.pctrisk*5; -x.ind1risk*5 ];%-x.ind2risk*5; 
prob.buc = [ x.x; 0;  x.pctrisk*5;  x.ind1risk*5 ]; %x.ind2risk*5; 

% prob.cones
prob.cones{1}.type = 'MSK_CT_QUAD';
prob.cones{1}.sub = [2*n1+1, 1:n1];

% prob.blx/bux
%maxwei 最高控制在总资金的5%
%minwei 做空位控制在沪深三百的指数权重内，以利于使用股指期货进行对冲，如股票a在指数权重为1%，则最多做空1%的仓位
%change 意味着每天该股票的turnover不应该超过该股票（平均每天）amount的5%
%pctrisk 为总资金的1%
prob.blx = [ x.minwei; -x.changel;           0 ];
prob.bux = [ x.maxwei;  x.changeu; x.pctrisk*3 ]; 

% min cx     
prob.c = [ -x.score; zeros(n1+1,1) ];
[err, res] = mosekopt('minimize echo(0)',prob);
err;
y(x.valid) = res.sol.itr.xx(1:n1);
