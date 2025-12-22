clear;

% training_imds = imageDatastore(fullfile(".","train","**","x20","**","500_500","**","SmallSize_*.jpg"),"LabelSource","foldernames");
% test_imds = imageDatastore(fullfile(".","test","**","x20","**","500_500","**","SmallSize_*.jpg"),"LabelSource","foldernames");
% validation_imds = imageDatastore(fullfile(".","validation","**","x20","**","500_500","**","SmallSize_*.jpg"),"LabelSource","foldernames");

df = struct2table(dir(fullfile("norm1_AI_STUDY","**","training_list.csv")));

for h = 2:2

    training_table = readtable(fullfile(df.folder{h},df.name{h}),"Delimiter",',','VariableNamingRule','preserve');
    validation_table = readtable(fullfile(df.folder{h},"validation_list.csv"),"Delimiter",',','VariableNamingRule','preserve');
    test_table = readtable(fullfile(df.folder{h},"test_list.csv"),"Delimiter",',','VariableNamingRule','preserve');

    training_imds = imageDatastore(strrep(training_table.Var1,"norm1","norm3"),"IncludeSubfolders",true,"LabelSource","foldernames");
    validation_imds = imageDatastore(strrep(validation_table.Var1,"norm1","norm3"),"IncludeSubfolders",true,"LabelSource","foldernames");
    test_imds = imageDatastore(strrep(test_table.Var1,"norm1","norm3"),"IncludeSubfolders",true,"LabelSource","foldernames");

    pixelRange = [-30 30];
    imageAugmenter = imageDataAugmenter( ...
        'RandXReflection',true, ...
        'RandYReflection',true,...
        'RandXTranslation',pixelRange, ...
        'RandYTranslation',pixelRange);


    load("nasnet_large_hinagata.mat");
    net = lgraph_1;

    augimds_Training = augmentedImageDatastore(net.Layers(1).InputSize(1:2),training_imds,DataAugmentation=imageAugmenter);
    augimds_Test = augmentedImageDatastore(net.Layers(1).InputSize(1:2),test_imds);
    augimds_Validation = augmentedImageDatastore(net.Layers(1).InputSize(1:2),validation_imds);


    training_option = trainingOptions( ...
        "sgdm", ...
        MiniBatchSize=64, ...
        MaxEpochs=5, ...
        Shuffle="every-epoch", ...
        Verbose=false, ...
        ValidationData=augimds_Validation,...
        ValidationFrequency=100,...
        InitialLearnRate=0.01, ...
        Plots="training-progress");

    net=trainNetwork(augimds_Training,net,training_option);

    % N = numel(test_imds.Labels);


    [labels,scores] = classify(net,augimds_Test);
    % confusionchart(test_imds.Labels,labels);



    ROCObject = rocmetrics(test_imds.Labels,scores,["AIH","DILI"]);
    % save(strcat("inceptionresnetv2_x20_no_nomarization_",num2str(ROCObject.AUC(1,1)),".mat"),"ROCObject");
    save(fullfile(df.folder{h},strcat("nasnet_large_x20_norm3_",num2str(ROCObject.AUC(1,1)),"_net",".mat")),"net");
    %
    % histogram(scores((test_imds.Labels == "AIH"),2),"BinWidth",0.01)
    % hold on
    % histogram(scores((test_imds.Labels == "DILI"),2),"BinWidth",0.01)
    % legend({"AIH","DILI"});
    % xlabel("DILI score");

    % clear;
    % 
    % training_imds = imageDatastore(fullfile(".","train","**","x20","**","500_500","**","norm1_*.jpg"),"LabelSource","foldernames");
    % test_imds = imageDatastore(fullfile(".","test","**","x20","**","500_500","**","norm1_*.jpg"),"LabelSource","foldernames");
    % validation_imds = imageDatastore(fullfile(".","validation","**","x20","**","500_500","**","norm1_*.jpg"),"LabelSource","foldernames");
    % 
    % pixelRange = [-30 30];
    % imageAugmenter = imageDataAugmenter( ...
    %     'RandXReflection',true, ...
    %     'RandYReflection',true,...
    %     'RandXTranslation',pixelRange, ...
    %     'RandYTranslation',pixelRange);
    % 
    % 
    % load("nasnet_large_hinagata.mat");
    % net=lgraph_1;
    % 
    % augimds_Training = augmentedImageDatastore(net.Layers(1).InputSize(1:2),training_imds,DataAugmentation=imageAugmenter);
    % augimds_Test = augmentedImageDatastore(net.Layers(1).InputSize(1:2),test_imds);
    % augimds_Validation = augmentedImageDatastore(net.Layers(1).InputSize(1:2),validation_imds);
    % 
    % 
    % training_option = trainingOptions( ...
    %     "sgdm", ...
    %     MiniBatchSize=20, ...
    %     MaxEpochs=5, ...
    %     Shuffle="every-epoch", ...
    %     Verbose=false, ...
    %     ValidationData=augimds_Validation,...
    %     ValidationFrequency=400,...
    %     Plots="training-progress", ...
    %     InitialLearnRate=0.0001);
    % 
    % net=trainNetwork(augimds_Training,net,training_option);
    % 
    % N = numel(test_imds.Labels);
    % 
    % 
    % [~,scores] = classify(net,augimds_Test);
    % 
    % 
    % 
    % ROCObject = rocmetrics(test_imds.Labels,scores,["AIH","DILI"]);
    % % save(strcat("inceptionresnetv2_x20_nomarization_",num2str(ROCObject.AUC(1,1)),".mat"),"ROCObject");
    % save(strcat("nasnet_large_x20_nomarization_",num2str(ROCObject.AUC(1,1)),"_net",".mat"),"net");

end
