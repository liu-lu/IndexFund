%主程序
%% 导入矩阵
addpath 'D:\Mosek\7\toolbox\r2013a'
cd( 'C:\Users\ZQC\Desktop\hs300\strategy')
% d1:因子测试开始日期 d2：因子测试结束日期
d1=datenum(2005,1,1) ;
d2=datenum(2015,11,30) ;
m = LoadMatrix(d1,d2);
cfg.startday = datenum(2014,1,1);

for di = 1 : length(m.daylist)
    TmpHS = m.hs300weights(:,di); 
    m.hs300(:,di) = TmpHS>0; 
end;

%% 定义策略参数
cfg.scale = 10000000;
cfg.fee =2/1000;
cfg.maxwei = 0.05; cfg.change = 0.05;
cfg.indexname = 'hs300weights';

%% 定义变量
% ops = m.ops;
% cps = m.cps;
% lps = m.lps;
% hps = m.hps;
% volume = m.volume;
m.alpha = nan( size(m.cps) );
m.alpha1 = nan( size(m.cps) );
m.score = nan( size(m.cps) );
%alphaname={'AD','RC6_2','CCI','RC1','ADTM','Aroon','VR','RSI','CR'};% 因子名称
%alphaname={'AD','Aroon','RSI','ADTM','CCI','CR','WVAD','RC7','RC5','VR','PVT6'};

%% 模拟

result.Holding = zeros(size(m.alpha) );
result.pnl = zeros(size(m.daylist));
result.r = result.pnl;
result.long = result.pnl; 
result.short = result.pnl;
result.longno = result.pnl; 
result.shortno = result.pnl;
result.tover = result.pnl;
result.risk = nan( size(result.pnl,1), 31 );
result.all = result.pnl;

for di = 2 : length(m.daylist)
    
    adj = m.adj(:,di);
    m.ops( adj > 1, 1 : di-1 ) = m.ops( adj > 1, 1 : di-1 ) ./ repmat( adj(adj>1),1,di-1 );
    m.cps( adj > 1, 1 : di-1 ) = m.cps( adj > 1, 1 : di-1 ) ./ repmat( adj(adj>1),1,di-1 );
    m.lps( adj > 1, 1 : di-1 ) = m.lps( adj > 1, 1 : di-1 ) ./ repmat( adj(adj>1),1,di-1 );
    m.hps( adj > 1, 1 : di-1 ) = m.hps( adj > 1, 1 : di-1 ) ./ repmat( adj(adj>1),1,di-1 );
    m.volume( adj > 1, 1 : di-1 ) = m.volume( adj > 1, 1 : di-1 ) .* repmat( adj(adj>1),1,di-1 );
    
    if m.daylist(di) < cfg.startday; continue; end
    disp(datestr(m.daylist(di),'yyyymmdd'));

%% 打分
    
     for j=1:length(alphaname)
        txt=['scores(:,j)=alpha_' alphaname{j} '(:,di);'];
        eval(txt);
        scores(~isfinite(scores(:,j)),j)= nan;
        scores(~isnan(scores(:,j)),j)=zscore(scores(~isnan(scores(:,j)),j));
        scores( isnan(m.hs300weights(:,di-1)),j)= nan;
        
    end;
    
    score=scores*w; % w为优化的权重
%     tmp = sqrt( median(m.amount(:,di-120:di-21),2) ./ max(m.amount(:,di-20:di-1),[],2) );
%     tmp(~isfinite(tmp)) = 0;
%     tmp = sum(tmp,2);
%     tmp(tmp==0) = nan;
%     pool = tmp < prctile(tmp(isfinite(tmp)),50) |  m.hs300weights(:,di-1) > 0 | isfinite(m.alpha(:,di-1));
%     score( ~pool ) = nan;
      score(1) = nan;
    %score( m.returns(:,di-1)-1 <= -0.07 )= nan;
      score( m.volume(:,di) < 1 )= nan;
    %tmp = m.score(:,di-1);
    %m.score(:,di) = tmp;
    m.score(:,di)= score;
    valid = isfinite(tmp) & isfinite(score);
    m.score(valid,di) = tmp(valid) * 0.6  + score(valid) * 0.4;
    valid = ~isfinite(tmp) & isfinite(score);
    m.score(valid,di) = score(valid);
    
    tradingday=weekday(m.daylist(di))-1;
    y = Prepare( m, cfg, di );
    if tradingday ==4 %| tradingday ==1 | tradingday ==5
        y = OptimizationLongshort( y );
        y = RoundHolding( m, y, cfg, di );
        m.alpha(:,di) = y;%每日早上的仓位
    else
        m.alpha(:,di) = m.alpha(:,di-1).*m.ops(:,di)./m.ops(:,di-1);
    end;
        m.alpha1(:,di) = m.alpha(:,di).*m.cps(:,di)./m.ops(:,di);%每日晚上的仓位
    
    [ pnl, long, short, longno, shortno, tover, risk ,Holding] = GetPNL(m, cfg ,di);
    
    
    result.Holding = zeros(size(m.alpha) );
    result.pnl(di,1) = pnl;
    result.r(di,1) = pnl/cfg.scale;
    result.long(di,1) = long;
    result.short(di,1) = short;
    result.longno(di,1) = longno; 
    result.shortno(di,1) = shortno;
    result.tover(di,1) = tover;
    result.toverper(di,1) = tover/cfg.scale;
    result.risk(di,:) = risk;
    result.all(di,:) = pnl+cfg.scale;
    cfg.scale=pnl+cfg.scale;
end


disp(cfg.scale);
%% 统计结果
% [ pnl, long, short, longno, shortno, tover, risk ,Holding ] = GetPNL(m, cfg);
% bool = m.daylist >= cfg.startday;
% dt=m.daylist(m.daylist>=cfg.startday);
% plot(dt,cumsum( pnl(bool) / cfg.scale ),'r','LineWidth',2)
% rtDate = dt(1);endDate =dt(end); xData = linspace(rtDate,endDate,8);
% set(gca,'XTick',xData)
% datetick('x','yyyy-mm-dd','keepticks');
% c=[m2xdate(m.daylist) pnl/cfg.scale];
% t=(m.daylist(end)-cfg.startday)/365;
% valid=m.daylist>cfg.startday;
% r=sum(pnl(valid))/cfg.scale/t;
% vol=std(pnl(valid)/cfg.scale)*sqrt(250);
% ir=r/vol;
% txt = sprintf( '%10s %12s %10s', ...
%          'Return%', 'Volatility%', 'InfoRatio');
% disp(txt);
% txt = sprintf( '%10.2f %12.2f %10.2f', ...
%         r*100,vol*100,ir);
% disp(txt);



txt = sprintf( '%4s %22s %10s %10s %12s %10s %10s %10s %10s %8s %8s', ...
    'Year', 'longMshort', 'longSshort', 'Return%', 'Volatility%', 'InfoRatio', 'Tover_yr%', 'Tover_day%', ...
    'drawdown%', 'dd_s','dd_e' );
disp(txt)

yr = unique(year(m.daylist( result.longno > 0 )));
for yi = 1 : length(yr)
    bool = year(m.daylist) == yr(yi);
    dates = m.daylist(bool);
    r = result.r(bool) ;
    tover_y = sum(result.toverper(bool)) ;
    tover_d = sum(result.toverper(bool)) / sum(bool);
    dd = Drawdown(r);
    ylong = mean(result.long(bool));
    yshort = mean(result.short(bool));
    ylongno = mean(result.longno(bool));
    yshortno = mean(result.shortno(bool));
    ls_money = [ num2str(round(ylong)) 'X' num2str(round(yshort)) ];
    ls_no = [ num2str(round(ylongno)) 'X' num2str(round(yshortno)) ];
    
    txt = sprintf( '%4d %22s %10s %10.2f %12.2f %10.2f %10.2f %10.2f %10.2f %8s %8s', ...
        yr(yi), ls_money, ls_no, sum(r)*100, std(r)*sqrt(250)*100, mean(r)/std(r)*sqrt(250), tover_y*100, tover_d*100, ...
        dd(1)*100, datestr(dates(dd(2)),'yyyymmdd'), datestr(dates(dd(3)),'yyyymmdd') );
    disp(txt)
    
end
