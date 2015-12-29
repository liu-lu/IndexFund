function x= MaxInformationRatio(ICCoVaMatrix, ICList , w0 )
% 复合因子IR最大化
% ICCoVaMatrix――协方差矩阵(n*n), ICList――均值(n*1), w0――权重之和
% Based on IR = IC/std(IC)
% minimize f
% subject to ICList'*y = 1,
%            Cholesky(ICCoVaMatrix)*y' = g, ||g||^2 <= f
%            sum(y) = t * w0,
%            t >=0, y >= 0

n = length(ICList);
p = size(ICCoVaMatrix,1);
prob.a = sparse([ICList,zeros(1,1+p+1);
                   chol(ICCoVaMatrix),zeros(p,1),eye(p),zeros(p,1);
                   ones(1,n),zeros(1,1+p),-w0]);
prob.c = [zeros(n,1);1;zeros(p+1,1)];
prob.cones{1}.type = 'MSK_CT_QUAD';
prob.cones{1}.sub = [n+1:n+1+p];
prob.blc = [1;zeros(p,1);0];
prob.buc = [1;zeros(p,1);0];
prob.blx = [zeros(n,1);(-inf*ones(1+p,1));0];  %-inf*ones(n,1)
prob.bux = [];
[err,res]=mosekopt('minimize echo(0)',prob);

y = res.sol.itr.xx(1:n);
f = res.sol.itr.xx(n+1);
g = res.sol.itr.xx(n+1+[1:p]);
t = res.sol.itr.xx(n+1+p+1);

%calculate the weight of factors 
x = y/t;
