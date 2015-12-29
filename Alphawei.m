%确定因子权重

%% 导入矩阵
addpath 'D:\Mosek\7\toolbox\r2013a'
cd( 'C:\Users\ZQC\Desktop\hs300\strategy')
d1=datenum(2005,1,1) ;
d2=datenum(2013,12,31);  %因子测试结束日期
m = LoadMatrix(d1,d2);
startday = datenum(2009,1,1);  %因子测试开始日期

returns = m.returns;
%%
%alphaname={'AD','RC6_2','CCI','RC1','ADTM','Aroon','VR','RSI','CR'};%hs300
alphaname={'AD','Aroon','RSI','ADTM','CCI','CR','WVAD','RC7','RC5','VR','PVT6'};%zz500


IC=nan(length(alphaname),length(m.daylist));
for di = 2 : length(m.daylist)
    if m.daylist(di) < startday; continue; end
    disp(datestr(m.daylist(di),'yyyymmdd'));

    for j=1:length(alphaname)
        txt=['scores(:,j)=alpha_' alphaname{j} '(:,di);'];
        eval(txt);
        scores(~isfinite(scores(:,j)),j)= nan;
        scores(~isnan(scores(:,j)),j)=zscore(scores(~isnan(scores(:,j)),j));
        scores( isnan(m.hs300weights(:,di-1)),j)= nan;
        
        tmp=~isnan(scores(:,j));
        B=corrcoef(scores(tmp,j),returns(tmp,di)-1);
        IC(j,di)=B(1,2);
    end;

end;

%% 因子权重

[w,ICList,ICstd,ICCoVaMatrix]=GetAlphaWei(IC);
IRList=ICList./ICstd*sqrt(250);


   

   

   
