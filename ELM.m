function [TrainingAccuracy, TestingAccuracy, label_actual] = elm(train_data, test_data, Elm_Type, NumberofHiddenNeurons, ActivationFunction)

% Usage: elm(TrainingData_File, TestingData_File, Elm_Type, NumberofHiddenNeurons, ActivationFunction)
% OR:    [TrainingTime, TestingTime, TrainingAccuracy, TestingAccuracy] = elm(TrainingData_File, TestingData_File, Elm_Type, NumberofHiddenNeurons, ActivationFunction)
%
% Input:
% TrainingData_File     - Filename of training data set
% TestingData_File      - Filename of testing data set
% Elm_Type              - 0 for regression; 1 for (both binary and multi-classes) classification
% NumberofHiddenNeurons - Number of hidden neurons assigned to the ELM
% ActivationFunction    - Type of activation function:
%                           'sig' for Sigmoidal function
%                           'sin' for Sine function
%                           'hardlim' for Hardlim function
%                           'tribas' for Triangular basis function
%                           'radbas' for Radial basis function (for additive type of SLFNs instead of RBF type of SLFNs)
%
% Output: 
% TrainingTime          - Time (seconds) spent on training ELM
% TestingTime           - Time (seconds) spent on predicting ALL testing data
% TrainingAccuracy      - Training accuracy: 
%                           RMSE for regression or correct classification rate for classification
% TestingAccuracy       - Testing accuracy: 
%                           RMSE for regression or correct classification rate for classification
%
% MULTI-CLASSE CLASSIFICATION: NUMBER OF OUTPUT NEURONS WILL BE AUTOMATICALLY SET EQUAL TO NUMBER OF CLASSES
% FOR EXAMPLE, if there are 7 classes in all, there will have 7 output
% neurons; neuron 5 has the highest output means input belongs to 5-th class
%
% Sample1 regression: [TrainingTime, TestingTime, TrainingAccuracy, TestingAccuracy] = elm('sinc_train', 'sinc_test', 0, 20, 'sig')
% Sample2 classification: elm('diabetes_train', 'diabetes_test', 1, 20, 'sig')
%
    %%%%    Authors:    MR QIN-YU ZHU AND DR GUANG-BIN HUANG
    %%%%    NANYANG TECHNOLOGICAL UNIVERSITY, SINGAPORE
    %%%%    EMAIL:      EGBHUANG@NTU.EDU.SG; GBHUANG@IEEE.ORG
    %%%%    WEBSITE:    http://www.ntu.edu.sg/eee/icis/cv/egbhuang.htm
    %%%%    DATE:       APRIL 2004

%%%%%%%%%%% Macro definition
REGRESSION=0;
CLASSIFIER=1;
r=2;
%%%%%%%%%%% Load training dataset
%train_data=load(TrainingData_File);
T=train_data(:,1)';
P=train_data(:,2:size(train_data,2))';
%clear train_data;                                   %   Release raw training data array

%%%%%%%%%%% Load testing dataset
%test_data=load(TestingData_File);
TV.T=test_data(:,1)';
TV.P=test_data(:,2:size(test_data,2))';
clear test_data;                                    %   Release raw testing data array

NumberofTrainingData=size(P,2);
NumberofTestingData=size(TV.P,2);
NumberofInputNeurons=size(P,1);

if Elm_Type~=REGRESSION
    %%%%%%%%%%%% Preprocessing the data of classification
    sorted_target=sort(cat(2,T,TV.T),2);
    label=zeros(1,1);                               %   Find and save in 'label' class label from training and testing data sets
    label(1,1)=sorted_target(1,1);
    j=1;
    %����label=[1,2,...,class]
    for i = 2:(NumberofTrainingData+NumberofTestingData)
        if sorted_target(1,i) ~= label(1,j)
            j=j+1;
            label(1,j) = sorted_target(1,i);
        end
    end
    
    number_class=j;
    NumberofOutputNeurons=number_class;
       
    %%%%%%%%%% Processing the targets of training
    temp_T=zeros(NumberofOutputNeurons, NumberofTrainingData);
    for i = 1:NumberofTrainingData
        for j = 1:number_class
            if label(1,j) == T(1,i)%ָ����j��Ϊ1������T�Ժ󣬵�j��Ļ�������T�е�j�ж�Ӧ��ѵ��������Ϊ1
                break; 
            end
        end
        temp_T(j,i)=1;
    end
    T=temp_T*2-1;

    %%%%%%%%%% Processing the targets of testing
    temp_TV_T=zeros(NumberofOutputNeurons, NumberofTestingData);
    for i = 1:NumberofTestingData
        for j = 1:number_class
            if label(1,j) == TV.T(1,i)
                break; 
            end
        end
        temp_TV_T(j,i)=1;
    end
    TV.T=temp_TV_T*2-1;

end                                                 %   end if of Elm_Type

%%%%%%%%%%% Calculate weights & biases
start_time_train=cputime;

%%%%%%%%%%% Random generate input weights InputWeight (w_i) and biases BiasofHiddenNeurons (b_i) of hidden neurons
InputWeight=rand(NumberofHiddenNeurons,NumberofInputNeurons)*2-1; %��Ϊ[-1,1]֮�����
BiasofHiddenNeurons=rand(NumberofHiddenNeurons,1);
tempH=InputWeight*P;
ind=ones(1,NumberofTrainingData);
BiasMatrix=BiasofHiddenNeurons(:,ind);             %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
tempH=tempH+BiasMatrix;

%%%%%%%%%%% Calculate hidden neuron output matrix H
switch lower(ActivationFunction)
    case {'sig','sigmoid'}
        %%%%%%%% Sigmoid %����һ��sigmoid�˱��ָ���
        %tempH=tempH/max(max(abs(tempH)));
        H = 1 ./ (1 + exp(-tempH));
               %ssss= sum(diag(H'*H))

    case {'sin','sine'}
        %%%%%%%% Sine
        H = sin(tempH);    
    case {'hardlim'}
        %%%%%%%% Hard Limit
        H = double(hardlim(tempH));
       % hl= sum(diag(H'*H))
    case {'tribas'}
        %%%%%%%% Triangular basis function
        H = tribas(tempH);
    case {'radbas'}
        %%%%%%%% Radial basis function
        H = radbas(tempH);
     case {'gauss'}
        %%%%%%%% Gauss
       P=P/max(max(abs(P)));
       G=[ones(NumberofHiddenNeurons,1)*sum(P.*P,1)-2*InputWeight*P+sum(InputWeight.*InputWeight,2)*ind].*[BiasofHiddenNeurons*ind];
        H = exp(-G/r);  
       % gaus= sum(diag(H'*H))
     case {'agauss'}
        %%%%%%%% 
        for i=1:NumberofHiddenNeurons
            InputWeighte(i,:)=InputWeight(i,:)/norm(InputWeight(i,:));
        end
        for j=1:NumberofTrainingData
            Pe(:,j)=P(:,j)/norm(P(:,j));
        end
        G=[(ones(NumberofHiddenNeurons,NumberofTrainingData)-InputWeighte*Pe)].*[BiasofHiddenNeurons*ind];
        G=2*G/max(max(abs(G)));
        H = exp(-G);  
      %  raf= sum(diag(H'*H))
        %%%%%%%% More activation functions can be added here                
end
clear P;                                            %   Release input of training data 
clear Pe; 
clear tempH;                                        %   Release the temparary array for calculation of hidden neuron output matrix H
%%%%%%%%%%% Calculate output weights OutputWeight (beta_i)
%OutputWeight=pinv(H') *T';   


%%
% faster method 1
 C=800;%2^5;%���򻯲���Ҳ����Ҫ%2��3�ն�ʦ�����õ�ֵΪ800
 OutputWeight=inv(eye(size(H,1))/C+H * H') * H * T';  
%max(max(OutputWeight))
%implementation; one can set regularizaiton factor C properly in classification applications 
%OutputWeight=(eye(size(H,1))/C+H * H') \ H * T';      % faster method 2
%implementation; one can set regularizaiton factor C properly in classification applications
%%
%OutputWeight=H*inv(eye(size(H,2))/C+ H'*H )*T';
%If you use faster methods or kernel method, PLEASE CITE in your paper properly: 

%Guang-Bin Huang, Hongming Zhou, Xiaojian Ding, and Rui Zhang, "Extreme Learning Machine for Regression and Multi-Class Classification," submitted to IEEE Transactions on Pattern Analysis and Machine Intelligence, October 2010. 

end_time_train=cputime;
TrainingTime=end_time_train-start_time_train ;       %   Calculate CPU time (seconds) spent for training ELM

%%%%%%%%%%% Calculate the training accuracy
Y=(H' * OutputWeight)';                             %   Y: the actual output of the training data
if Elm_Type == REGRESSION
    TrainingAccuracy=sqrt(mse(T - Y));               %   Calculate training accuracy (RMSE) for regression case
end
clear H;

%%%%%%%%%%% Calculate the output of testing input
start_time_test=cputime;
tempH_test=InputWeight*TV.P;         
ind=ones(1,NumberofTestingData);
BiasMatrix=BiasofHiddenNeurons(:,ind);              %   Extend the bias matrix BiasofHiddenNeurons to match the demention of H
tempH_test=tempH_test + BiasMatrix;
switch lower(ActivationFunction)
    case {'sig','sigmoid'}
        %%%%%%%% Sigmoid 
        %tempH_test=tempH_test/max(max(abs(tempH_test)));
        H_test = 1 ./ (1 + exp(-tempH_test));
    case {'sin','sine'}
        %%%%%%%% Sine
        H_test = sin(tempH_test);        
    case {'hardlim'}
        %%%%%%%% Hard Limit
        H_test = hardlim(tempH_test);        
    case {'tribas'}
        %%%%%%%% Triangular basis function
        H_test = tribas(tempH_test);        
    case {'radbas'}
        %%%%%%%% Radial basis function
        H_test = radbas(tempH_test);  
     case {'gauss'}
        %%%%%%%% Gauss
        TV.P=TV.P/max(max(abs(TV.P)));
       G=[[ones(NumberofHiddenNeurons,1)*sum(TV.P.*TV.P,1)]-2*InputWeight*TV.P+sum(InputWeight.*InputWeight,2)*ind].*[BiasofHiddenNeurons*ind];
       H_test = exp(-G/r);
      case {'agauss'}
        %%%%%%%% 
        for j=1:NumberofTestingData
            Pte(:,j)=TV.P(:,j)/norm(TV.P(:,j));
        end
        G=[(ones(NumberofHiddenNeurons,NumberofTestingData)-InputWeighte*Pte)].*[BiasofHiddenNeurons*ind];
        G=2*G/max(max(abs(G)));
        H_test = exp(-G);  
        %%%%%%%% More activation functions can be added here        
end
clear TV.P;             %   Release input of testing data   
clear InputWeighte; 
clear Pte;
clear G;
TY=(H_test' * OutputWeight)';                      %   TY: the actual output of the testing data
end_time_test=cputime;
TestingTime=end_time_test-start_time_test ;          %   Calculate CPU time (seconds) spent by ELM predicting the whole testing data

if Elm_Type == REGRESSION
    TestingAccuracy=sqrt(mse(TV.T - TY));            %   Calculate testing accuracy (RMSE) for regression case
end

if Elm_Type == CLASSIFIER
%%%%%%%%%% Calculate training & testing classification accuracy
    MissClassificationRate_Training=0;
    MissClassificationRate_Testing=0;

    for i = 1 : size(T, 2)
        [x, label_index_expected]=max(T(:,i));
        [x, label_index_actual]=max(Y(:,i));
        if label_index_actual~=label_index_expected
            MissClassificationRate_Training=MissClassificationRate_Training+1;
        end
    end
    TrainingAccuracy=1-MissClassificationRate_Training/size(T,2);
    % 2018.2.28 added
    label_actual = [];
    for i = 1 : size(TV.T, 2)
        [x, label_index_expected]=max(TV.T(:,i));
        [x, label_index_actual]=max(TY(:,i));
        if label_index_actual~=label_index_expected
            MissClassificationRate_Testing=MissClassificationRate_Testing+1;
            label_actual = [label_actual; 0];
        else
            label_actual = [label_actual; 1];
        end
    end
    TestingAccuracy=1-MissClassificationRate_Testing/size(TV.T,2);  
end