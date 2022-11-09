function [gbestX,gbestfitness,gbesthistory]= EMTLBO(PopSize,D,xmax,xmin,vmax,vmin ,MaxIter,Func,FuncId)
win1=0;win2=0;win3=0;
p=0;swit=0;
Fitness=Func;
number=zeros(1,6);
Counters=zeros(1,6);
popsize=PopSize;
dimension=D;
maxiter=MaxIter;
tfitness=inf;
Ceq1=zeros(1,dimension);     fitness1=inf;
Ceq2=zeros(1,dimension);     fitness2=inf;
Ceq3=zeros(1,dimension);     fitness3=inf;
Ceq4=zeros(1,dimension);     fitness4=inf;
FEs=0;
MaxFEs=popsize*maxiter;
teacher=[];
fitness=nan(popsize,1);
gbestfitness=inf;
xmean=zeros(1,dimension);
newx=rand(popsize,dimension);
x=zeros(popsize,dimension);
for i=1:popsize
    x(i,:)=xmin+(xmax-xmin).*rand(1,dimension);
end
flag=0;
for i=1:popsize
    fitness(i)=Fitness(x(i,:)',FuncId);
    FEs=FEs+1;
    if fitness(i)<tfitness
        tfitness=fitness(i);
        teacher=x(i,:);
    end
    if gbestfitness>fitness(i)
        gbestfitness=fitness(i);
    end
    gbesthistory(FEs)=gbestfitness;
    fprintf("ELMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
end
iter=1;
while FEs<=MaxFEs-popsize
    xmean=(1/popsize).*sum(x,1);
    %Teaching phase
    for i=1:popsize
        if iter~=1
            teacher=C_pool(randi(size(C_pool,1)),:);
        end
        TF=randi([1,2]);
        newx(i,:)=x(i,:)+rand(1,dimension) .*(teacher-TF.*xmean);
        newx(i,:)=max(newx(i,:),xmin);
        newx(i,:)=min(newx(i,:),xmax);
        newfitness=Fitness(newx(i,:)',FuncId);
        FEs=FEs+1;
        if fitness(i)>newfitness               
            fitness(i)=newfitness;
            x(i,:)=newx(i,:);
        end
        if gbestfitness>fitness(i)
            gbestfitness=fitness(i);
        end
        gbesthistory(FEs)=gbestfitness;
        fprintf("EMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
    end
    %Learner phase
    for i=1:popsize
        vec=[1:i-1,i+1:popsize];
        L1=vec(randi(popsize-1));
        if fitness(i)<fitness(L1)
            newx(i,:)=x(i,:)+rand(1,dimension).*(x(i,:)-x(L1,:));
        else
            newx(i,:)=x(i,:)+rand(1,dimension).*(x(L1,:)-x(i,:));
        end
        newx(i,:)=max(newx(i,:),xmin);
        newx(i,:)=min(newx(i,:),xmax);
        newfitness=Fitness(newx(i,:)',FuncId);
        FEs=FEs+1;
        if fitness(i)>newfitness
            fitness(i)=newfitness;
            x(i,:)=newx(i,:);
        end
        if gbestfitness>fitness(i)
            gbestfitness=fitness(i);
        end
        gbesthistory(FEs)=gbestfitness;
        fprintf("EMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
    end
    %Mutation operator pool
    Difference=zeros(1,6);
    if (rand<(0.8-p))||(iter==1)
        %DE pool
        for i=1:popsize
            F=fitness(i)/max(fitness);
            if iter~=1
                teacher=C_pool(randi(size(C_pool,1)),:);
            end
            random=selectID(popsize,i,5);
            L1=random(1);
            L2=random(2);
            L3=random(3);
            L4=random(4);
            L5=random(5);
            if swit==0
                flag=flag+1;
            end
            switch flag
                case 1
                    newx(i,:)=x(L1,:)+F*(x(L2,:)-x(L3,:));   %DE/rand/1
                case 2
                    newx(i,:)=x(L1,:)+F*(x(L2,:)-x(L3,:))+F*(x(L4,:)-x(L5,:));   %DE/rand/2
                case 3
                    newx(i,:)=x(i,:)+F*(teacher-x(i,:))+F*(x(L1,:)-x(L2,:));   %DE/current-to-best/1
                case 4
                    newx(i,:)=teacher+F*(x(L1,:)-x(L2,:));   %DE/best/1
                case 5
                    newx(i,:)=teacher+F*(x(L1,:)-x(L2,:))+F*(x(L3,:)-x(L4,:));   %DE/best/2
                case 6
                    newx(i,:)=x(i,:)+F*(teacher-x(L1,:))+F*(x(L2,:)-x(L3,:));   %DE/rand-to-best/1
            end
            number(flag)=number(flag)+1;
            newx(i,:)=max(newx(i,:),xmin);
            newx(i,:)=min(newx(i,:),xmax);
            beforefitness=fitness(i);
            newfitness=Fitness(newx(i,:)',FuncId);
            FEs=FEs+1;
            if newfitness<fitness(i)
                fitness(i)=newfitness;
                x(i,:)=newx(i,:);
                win1=1;
                win1flag=flag;
            end
            if gbestfitness>fitness(i)
                gbestfitness=fitness(i);
                win2=1;
                win2flag=flag;
                p=p-0.01;
                p=max(p,0);    %不能为负
            end
            gbesthistory(FEs)=gbestfitness;
            fprintf("EMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
            Difference(flag)=beforefitness-fitness(i);
            beforeflag=flag;
            if swit==1
                if   win1==1&&win2~=1
                    if rand<0.5
                        flag;
                    else
                        [~,flag]=max(Difference);
                        if isempty(flag)
                            flag=randperm(6,1);
                        end
                        if flag==beforeflag   %如果随机到的还是之前用的或者上次使用
                            Counters(flag)=Counters(flag)+1;   %重复连续使用计数器，防止一个算子被使用很多次
                            if Counters(flag)==3
                                flagvec=[1:flag-1,flag+1:6];
                                flag=flagvec(randperm(size(flagvec,2),1));
                                Counters(flag)=0;        %计数器清零
                            end
                        else
                            Counters(flag)=0;
                        end
                    end
                elseif win1~=1&&win2~=1
                    flagvec=[1:flag-1,flag+1:6];
                    flag=flagvec(randperm(size(flagvec,2),1));
                elseif win1==1&&win2==1
                    flag=beforeflag;
                else
                    fprintf('不可能');
                    pause(1)
                end
            end
            win1=0;win2=0;
            if flag==6&&swit==0          %第一次7个算子都做一遍,不加swit==0，第一代前7次后还会做
                [~,flag]=max(Difference);
                swit=1;   %关闭开关
            end
        end
    else
        %GA pool
        for i=1:popsize
            newx(i,:)=x(i,:);
            M=randperm(dimension,1);
            if 0.5>rand                       %均匀变异,迭代早期使用
                for j=1:size(M,2)
                    newx(i,M(j))=xmin+rand*(xmax-xmin);
                end
            else
                for j=1:size(M,2)                             %非均匀变异，迭代后期使用
                    newx(i,M(j))=x(i,M(j))+1.0*randn;
                end
            end
            newx(i,:)=max(newx(i,:),xmin);     %对新个体越界处理
            newx(i,:)=min(newx(i,:),xmax);
            newfitness=Fitness(newx(i,:)',FuncId);
            FEs=FEs+1;
            if newfitness<fitness(i)
                fitness(i)=newfitness;
                x(i,:)=newx(i,:);
            end
            if gbestfitness>fitness(i)
                gbestfitness=fitness(i);
                win3=1;
            end
            gbesthistory(FEs)=gbestfitness;
            fprintf("EMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
        end
        if win3==1
            p=p+0.01;
            win3=0;
            p=min(p,0.6);
        end
    end
    swit=0;
    flag=0;
    %Elite pool
    for i=1:popsize
        flag_max=x(i,:)>xmax;
        flag_min=x(i,:)<xmin;
        x(i,:)=(x(i,:).*(~(flag_max+flag_min)))+xmax.*flag_max+xmin.*flag_min;
        if fitness(i)<fitness1
            Ceq1=x(i,:);fitness1=fitness(i);
        elseif fitness(i)>fitness1&&fitness(i)<fitness2
            Ceq2=x(i,:);fitness2=fitness(i);
        elseif fitness(i)>fitness1&&fitness(i)>fitness2&&fitness(i)<fitness3
            Ceq3=x(i,:);fitness3=fitness(i);
        elseif fitness(i)>fitness1&&fitness(i)>fitness2&&fitness(i)>fitness3&&fitness(i)<fitness4
            Ceq4=x(i,:);fitness4=fitness(i);
        end
    end
    Cave=(Ceq1+Ceq2+Ceq3+Ceq4)/4;
    C_pool=[Ceq1;Ceq2;Ceq3;Ceq4;Cave];
    teacher=C_pool(randi(size(C_pool,1)),:);
    gbestfitness=fitness1;
    gbesthistory(FEs)=gbestfitness;
    FEs=FEs+1;
    fprintf("EMTLBO 第%d次评价，最佳适应度 = %e\n",FEs,gbestfitness);
    iter=iter+1;
end
if FEs<MaxFEs
    gbesthistory(FEs+1:MaxFEs)=gbestfitness;
else
    if FEs>MaxFEs
        gbesthistory(MaxFEs+1:end)=[];
    end
end
gbestX=Ceq1;
    function [r]=selectID(popsize,i,count)
        if count<= popsize
            vecc=[1:i-1,i+1:popsize];
            r=zeros(1,count);
            for kkk =1:count
                n = popsize-kkk;
                t = randi(n,1,1);
                r(kkk) = vecc(t);
                vecc(t)=[];
            end
        end
    end
end