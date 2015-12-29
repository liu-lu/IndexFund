function y = Prepare( m, cfg, di )
% 准备风险和优化

%% load holding & tover
x = m.alpha(:,di-1).*m.ops(:,di)./m.ops(:,di-1);
y.x = x;

%% load beta
if isfield( m, 'betas' )
    y.betas = m.betas(:,di-1);
end

%% load index
%将指数股票的权重单位化
if ismember( cfg.indexname, fields(m) )
    index = m.(cfg.indexname)(:,di-1);
    index(index>0) = index(index>0) / sum( index(index>0) );
    y.index = index;
end
    
%% load industry
if isfield( m, 'ind1' ) && isfield( m, 'ind2' )
    y.ind1 = m.ind1(:,di);
    y.ind2 = m.ind2(:,di);
end

y.maxwei = cfg.maxwei * cfg.scale * ones( size(m.stocklist) );
y.minwei = - cfg.scale * y.index;

%% load change
change = m.amount(:,di-20:di-1);
change(isnan(change)) = 0;
change = sum(change,2) ./ sum(change>0,2);
change = change * cfg.change;
%当日停牌股票的判断。
change(m.volume(:,di)<1)=0;
changeu=change;
changel=change;
%涨(跌)停股票判断
changeu(m.cps(:,di)==m.lps(:,di)&m.hps(:,di)==m.lps(:,di)&m.ops(:,di)==m.lps(:,di)&m.cps(:,di)>m.cps(:,di-1))=0;
changel(m.cps(:,di)==m.lps(:,di)&m.hps(:,di)==m.lps(:,di)&m.ops(:,di)==m.lps(:,di)&m.cps(:,di)<m.cps(:,di-1))=0;
y.changeu = changeu;
y.changel = changel;

%% load risk
y.pctrisk = cfg.scale / 100;
y.scale = cfg.scale;

%% load score
y.score = m.score(:,di);

%% get n
n = size(m.score,1);

%% valid data
valid = isfinite(y.score) & isfinite(y.betas) & isfinite(y.ind1) & isfinite(y.ind2);
valid(y.index>0) = true;
valid( isfinite(y.x) ) = true;
valid(1) = false;

tmp1 = y.x;	tmp1( ~(tmp1>0) ) = 0;
tmp2 = y.minwei; tmp2( ~(tmp2<0)) = 0;
y.x = tmp1 + tmp2; 
y.x(1) = 0;

%% fill missing data
names = { 'score'; 'betas' };
for ni = 1 : length(names)
    if isfield( y, names{ni} )
        tmp = y.(names{ni})(valid);
        tmp = median(tmp(isfinite(tmp)));
        y.(names{ni})( valid & isnan(y.(names{ni})) ) = tmp;  
    end
end

%% change size
names = fields(y);
for ni = 1 : length(names)
    if size(y.(names{ni}),1) == n && size(y.(names{ni}),2) == 1
        y.(names{ni}) = y.(names{ni})(valid);
        y.(names{ni})( isnan(y.(names{ni})) ) = 0;
    end
end
n1 = sum(valid);
y.n1 = n1;
y.valid = valid;

%% industry
ind1s = unique( y.ind1 ); ind1s = setdiff(ind1s,0); nind1 = length(ind1s);
ind1 = zeros(nind1,n1);
y.ind1risk = y.pctrisk * ones( nind1, 1 );
for ni = 1 : nind1
    ind1(ni,:) = ( y.ind1 == ind1s(ni) )';
    wei = y.index( y.ind1 == ind1s(ni) ) * cfg.scale;
    %行业偏离或者是1%的总资金，或者是指数中该行业股票的总权重*总资金/5
    y.ind1risk(ni) = max( y.ind1risk(ni), sum(wei(wei>0))/5 );

end
y.ind1 = ind1;
y.nind1 = nind1;

ind2s = unique( y.ind2 ); nind2 = length(ind2s);
ind2 = zeros(nind2,n1);
y.ind2risk = y.pctrisk * ones( nind2, 1 );
for ni = 1 : nind2
    ind2(ni,:) = ( y.ind2 == ind2s(ni) )';
    wei = y.index( y.ind2 == ind2s(ni) ) * cfg.scale;
    y.ind2risk(ni) = max( y.ind2risk(ni), sum(wei(wei>0))/5 );
   
end
y.ind2 = ind2;
y.nind2 = nind2;
