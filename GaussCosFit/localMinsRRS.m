% %��ʯ��(FeiShiFa)
% %Random Running Stones
% %Expulso
% 
% clear;clc;tic;
% syms a1 a2 a3 a4
% % Test part1, formulas for different dims
% % r2=x1.^2+2.*x2.^2;
% % r3=x1.^2+3.*x2.^2+2.*x3.^2+2.*x4.^2;
% % z=cos(x1).*x1;
% % z=x1.^5./10000;
% % z=sqrt(r2)+30;
% % z=10-10.*exp(-r2./100).*cos(2.*pi./5.*sqrt(r2));
% % z=sqrt(r3)+30;
% % boundaryLim=...
% %     [-20,-20,-20,-20,-20;%Lower Lim
% %     20,20,20,20,20];%Higher Lim
% %Dim1,Dim2,Dim3
% % Test part2, formulas for fitting scatters
% % boundaryLim=...
% %     [0,-2,-20,-20,-20;%Lower Lim
% %     10,20,20,20,20];%Higher Lim
% boundaryLim=...
%     [0,-2,-20,-20;%Lower Lim
%     10,20,20,20];%Higher Lim
% syms x yv
% yInit=exp(-x^2./pi*2)*cos(x./1*3*pi)*5+1;yInitFunc=matlabFunction(yInit);
% yFit=exp(-x^2./pi*2)*cos(x.*a1)*a2+1;yFitFunc=matlabFunction(yFit);
% nParaVars=2;
% yf=yFit-yv;nVars=length(symvar(yf));
% yfFunc=matlabFunction(yf);
% nScatters=80;x1Vec=linspace(boundaryLim(1,1),boundaryLim(2,1),nScatters)';
% scatters=[x1Vec,yInitFunc(x1Vec)+randi(5,nScatters,1)./5-0.5];
% scatterFig=figure;
% plot(scatters(:,1),scatters(:,2),'o');
% iVars=[nVars-1,nVars];
% yfFuncs=funcByVal(yfFunc,iVars,scatters);
% % varsV=num2cell(symvar(yf));varsV(iVars)=mat2cell(scatters,length(scatters),[1,1]);
% % z=sqrt(simplify(sum((yfFuncs./sqrt(1+x1.^2)).^2))./(1e1));
% % z=sqrt(simplify(sum((yfFuncs./1).^2))./(1e1));
% z=sqrt(sum((yfFuncs./1).^2)./(1e1));
% % z=vpa(z);
% zFunc=matlabFunction(z);
% minPos=localMinsRRS1(zFunc,boundaryLim);
% [minZ,minR]=min(minPos(:,end));
% yR=funcByVal(yFitFunc,1:nParaVars,minPos(minR,1:nParaVars));
% % hold on;
% plotFuncOn(x1Vec(1),x1Vec(end),matlabFunction(yR),scatterFig);
% toc;
function [pos,fig]=localMinsRRS(zFunc,bdLim)
% zFunc=matlabFunction(f(xi))
% bdLim=[UpLim_x1 UpLim_x2 ... UpLimZv;
%        LoLim_x1 LoLim_x2 ... LoLimZv;]
tic;
syms zv
fFunc=matlabFunction(zFunc-zv);
varsList=symvar(sym(fFunc));varsListStr=string(varsList);
nVar=length(varsList);
bdLim=[bdLim(:,1:nVar-1),[-Inf;Inf]];
rpics=2;cpics=2;
fig=figure;
subplot(rpics,cpics,1);
x1v=linspace(bdLim(1,1),bdLim(2,1),100);
if nVar>=3
    x2v=linspace(bdLim(1,2),bdLim(2,2),100);
    [x1Grid,x2Grid]=ndgrid(x1v,x2v);
    xyuGridCell=[{x1Grid},{x2Grid}];
    if nVar>3
        uCell=num2cell(mean(bdLim(:,3:nVar-1)));
        xyuGridCell=[xyuGridCell,uCell];
    end
    zGrid=zFunc(xyuGridCell{:});
    plot3D(x1Grid,x2Grid,zGrid,zGrid);xlabel('Dim1');ylabel('Dim2');zlabel('z');hold on;
else % nVar==2
    zGrid=zFunc(x1v);
    plot(x1v,zGrid,'--','LineWidth',0.5,'color','black');hold on;
end
err=1e-20;% zero
vError=1e-10;% zero for velocity
dzError=1e-3;% zero for dz
nDim=nVar;% motion dimision or number of variates
dt=0.05;% time evolution factor
m0=1;
g=9.8;
mu=0.2;%friction factor
GVec=zeros(1,nDim);GVec(end)=-1;
GVec=GVec.*m0*g;
sVec=jacobian(fFunc,varsList);
sBV=vpa(sVec./norm(sVec));
tic;sBVFunc=matlabFunction(sBV);toc;
varBvList=symvar(sBV);varBvListStr=string(varBvList);
[~,varsIndex]=find(varsListStr==varBvListStr');nVarBv=length(varBvList);

nPoints=100;
nPerDim=floor(nPoints^(1/(nDim-1)));
nTotalDim=nPerDim^(nDim-1);
nRand=nPoints-nTotalDim;
nFlys=40;
activePList=1:nPoints;
activePListLen=length(activePList);
% pos=rand(nPoints,nDim);% Each row as the position of a point(random produce)
seedR=linspace(0,1,nPerDim);
ndGridPara=mat2cell(repmat(seedR',1,nDim-1),nPerDim,ones(1,nDim-1));
gridCell=cell(1,nDim-1);[gridCell{:}]=ndgrid(ndGridPara{:});
gridMat=NaN(nTotalDim,nDim-1);
for iGrid=1:nDim-1
%     matCache=gridCell{iGrid};
    gridMat(:,iGrid)=reshape(gridCell{iGrid},nTotalDim,1);
end
pos=[gridMat;rand(nRand,nDim-1)];% Each row as the position of a point
pos=[pos,zeros(nPoints,1)];

pos=repmat(bdLim(1,:),nPoints,1)+repmat(bdLim(2,:)-bdLim(1,:),nPoints,1).*pos;
posActiCell_z=mat2cell(pos(activePList,1:nDim-1),activePListLen,ones(1,nDim-1));
pos(activePList,end)=zFunc(posActiCell_z{:});% Initial positions on surface
GVec=repmat(GVec,nPoints,1);
vmVec=zeros(nPoints,nDim);
vmVnorm=zeros(nPoints,nDim)+err;
dtVec=ones(1,1).*dt;
Ndz=10;dzMat=ones(nPoints,Ndz).*10;
stopFlag=0;
count=0;
while stopFlag==0 && count<100 || count<=Ndz    
    activePListLen=length(activePList);
    posA=pos(activePList,:);    GVecA=GVec(activePList,:);    vmVecA=vmVec(activePList,:); vmVnormA=vmVnorm(activePList,:);
    posActiCell_BV=mat2cell(posA(:,varsIndex),activePListLen,ones(1,nVarBv));
    sBV_v=sBVFunc(posActiCell_BV{:});
    FgpVec=GVecA-repmat(dot(GVecA,sBV_v,2),1,nDim).*sBV_v;
    fVec=-abs(repmat(dot(GVecA,sBV_v,2),1,nDim)).*vmVecA./vmVnormA.*mu;
    aVec=(FgpVec+fVec)./m0;
    dvVec=aVec.*dtVec;
    vmVecA=vmVecA+dvVec;vmVecA(:,end)=0;
    rVec=vmVecA.*dtVec;
    flySeq=0:nFlys-1;flySeq=reshape(flySeq,1,1,nFlys);
    rVecFlys=rVec.*flySeq;
    posRep=repmat(posA,1,1,nFlys);
    posRep=posRep+rVecFlys;
    bdLoRep=repmat(bdLim(1,1:nDim-1),activePListLen,1,nFlys);%%boundary Check
    bdUpRep=repmat(bdLim(2,1:nDim-1),activePListLen,1,nFlys);
    bdOutUpIndex=find(posRep(:,1:nDim-1,:)>bdUpRep);
    bdOutLoIndex=find(posRep(:,1:nDim-1,:)<bdLoRep);
    if ~isempty(bdUpRep)
        bdUpRepNd=linerIndex2Nd(bdOutUpIndex,[activePListLen,nDim,nFlys]);
        posRep(bdUpRepNd(:,1),1:nDim-1,bdUpRepNd(:,3))=bdUpRep(bdUpRepNd(:,1),1:nDim-1,bdUpRepNd(:,3));
    end
    if ~isempty(bdLoRep)
        bdLoRepNd=linerIndex2Nd(bdOutLoIndex,[activePListLen,nDim,nFlys]);
        posRep(bdLoRepNd(:,1),1:nDim-1,bdLoRepNd(:,3))=bdLoRep(bdLoRepNd(:,1),1:nDim-1,bdLoRepNd(:,3));
    end
    posRepActiCell_z=mat2cell(posRep(:,1:nDim-1,:),activePListLen,ones(1,nDim-1),nFlys);
    posZFlys=reshape(zFunc(posRepActiCell_z{:}),activePListLen,nFlys);
    [zMins,zMinsIndex]=min(posZFlys,[],2);
    zMinsIndexE1=find(zMinsIndex==1);
%     zMinsIndexE1=find(zMinsIndex<nFlys);
    if ~isempty(zMinsIndexE1)
        vmVecA(zMinsIndexE1,:)=vError;
    end        
    xyMinsPos=NaN(activePListLen,nDim-1);
    for index=1:activePListLen
        xyMinsPos(index,:)=posRep(index,1:nDim-1,zMinsIndex(index));
    end
    oldPos=pos;
    posA=[xyMinsPos,zMins];    pos(activePList,:)=posA;
    count=count+1;    
    dz=pos(:,end)-oldPos(:,end);
    dzA=dz(activePList,end);
    upGoIndex=find(dzA>0);
    if ~isempty(upGoIndex)
        vmVecA(upGoIndex,:)=0;
    end
    vmVec(activePList,:)=vmVecA; 
    vmVnorm=repmat(vecnorm(vmVec,2,2),1,nDim)+err;
    dzMat=circshift(dzMat,-1,2);dzMat(:,end)=dz;dzMatAver=mean(dzMat,2);
    
    figure(fig);subplot(rpics,cpics,1);
    if exist('handleS','var')
        delete(handleS);
    end
    hold on;
    if nVar>=3
        handleS=scatter3(pos(:,1),pos(:,2),pos(:,end),'.');title('Position');
    else %nvar=2
        handleS=scatter(pos(:,1),pos(:,2),'.');title('Position');
    end
    countRep=repmat(count,nPoints,1);
    subplot(rpics,cpics,2);hold on;scatter(countRep,pos(:,end),'.');title(['z',string(max(pos(:,end)))]);
    if count>Ndz
        subplot(rpics,cpics,3);hold on;scatter(countRep,dzMatAver,'.');title(['dzAver',string(max(dzMatAver))]);
    end
    subplot(rpics,cpics,4);hold on;scatter(repmat(count,activePListLen,1),activePList,'.');title(['activePList',string(activePListLen)]);
    drawnow;
    %z and position compare, combine closed points
    errComp=min(bdLim(2,:)-bdLim(1,:))/1000;
    [~,indexSortPos]=sort(posA(:,end));
    sortPos=posA(indexSortPos,:);
    dPos=sortPos(1:end-1,:)-sortPos(2:end,:);    
    indexCompA=find(vecnorm(dPos,2,2)<errComp);
    indexComp=[];
    if ~isempty(indexCompA)
        indexComp=activePList(indexSortPos(indexCompA));
        indexComp=reshape(indexComp,length(indexComp),1);
    end
    %convergence condition
    dzA0Index=find(abs(dzMatAver)<dzError);
    stopIndex=unique([dzA0Index;indexComp]);
    if ~isempty(stopIndex)
        activePList=setdiff(activePList,stopIndex);
    end
    if isempty(activePList)
        stopFlag=1;
    end
end
end