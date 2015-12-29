function [w,ICList,ICstd,ICCoVaMatrix]=GetAlphaWei(IC)
%获取因子权重
n=size(IC,1);
txt=['~isnan(IC(1,:))'];
for j=2:n
    txt=[txt '& ~isnan(IC(' num2str(j) ',:))'];
end;
    txt=['tmp=' txt ';'];
    eval(txt);
    ICvalid=IC(:,tmp);
    ICList=mean(ICvalid,2); 
    ICList=ICList';
for j=1:n
    ICstd(1,j)=sqrt(var(ICvalid(j,:)));
end;
    ICCoVaMatrix=cov(ICvalid');
    w = MaxInformationRatio(ICCoVaMatrix, ICList , 1 );
end
