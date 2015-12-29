%%  导入数据  quotes weight等
clear;
load('quotes.mat');
% load('finance.mat');
load('adj.mat');
load('returns.mat');
load('hs300wei.mat');
load('zz500wei.mat');
load('universeall.mat');
ns=size(adj,1);
nd=size(adj,2);

%% 生成因子矩阵scores   ns*nd   ns：共2791支股票    nd：交易日共2659天
alpha_SI=nan(ns,nd);
for di = 2 : nd
    
    adji = adj(:,di);
    ops( adji > 1, 1 : di-1 ) = ops( adji > 1, 1 : di-1 ) ./ repmat( adji(adji>1),1,di-1 );
    cps( adji > 1, 1 : di-1 ) = cps( adji > 1, 1 : di-1 ) ./ repmat( adji(adji>1),1,di-1 );
    lps( adji > 1, 1 : di-1 ) = lps( adji > 1, 1 : di-1 ) ./ repmat( adji(adji>1),1,di-1 );
    hps( adji > 1, 1 : di-1 ) = hps( adji > 1, 1 : di-1 ) ./ repmat( adji(adji>1),1,di-1 );
    volume( adji > 1, 1 : di-1 ) = volume( adji > 1, 1 : di-1 ) .* repmat( adji(adji>1),1,di-1 );
    mid = (cps+hps+lps)/3;
    
    if di < 900; continue; end;   
    disp(di);
    
    %% 因子输入区域
    alpha_SI(:,di)=cps(:,di-1)./mean(cps(:,[di-3:di-1]),2);
   
end;
%%  
% alpha_AD=nan(ns,nd);
% for di=900:nd
%    alpha_AD(:,di) = sum(AD(:,[di-5:di]),2);
% end;


%% 计算IC矩阵   因子测试区间：startday~endday
scores=alpha_SI;
IC=nan(1,nd);
startday=min(find(daylist>=datenum(2009,1,1)));
endday=max(find(daylist<=datenum(2013,12,31)));
for di=startday:endday
    score=scores(:,di);
    score(~isnan(score()))=zscore(score(~isnan(score()))); %标准化
    score( isnan(zz500wei(:,di-1)))= nan; %限定范围
    score(~isfinite(score()))= nan; %去掉无限值
    tmp=~isnan(score());
    sigma=corrcoef(score(tmp),returns(tmp,di)-1); %相关矩阵
    IC(1,di)=sigma(1,2);  %IC
end;
% 输出因子IC的均值、标准差等

    ICvalid(:,1)=IC(1,~isnan(IC(1,:)));
    ICmean=mean(ICvalid(:,1));    %IC均值
    ICstd=sqrt(var(ICvalid(:,1)));  %IC标准差
    IR=ICmean./ICstd*sqrt(250);   %IR
    win=sum(ICvalid>0)/size(ICvalid,1);
