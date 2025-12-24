test_path = fullfile(".","test.csv");
validation_path = fullfile(".","validation.csv");
train_path = fullfile(".","training.csv");

% 画像が入っているディレクトリのルートフォルダパス
root = "";

resolution = "x20" ;
image_size = "224_224" ;

color_change_flag = false ; % 色変換を施した画像は使わずに，元データのみでの学習とする．

test_path_table = readtable(test_path,"Delimiter",",","ReadRowNames",false);
validation_path_table = readtable(validation_path,"Delimiter",",","ReadRowNames",false);
train_path_table = readtable(train_path,"Delimiter",",","ReadRowNames",false);

t = arrayfun(@originalCroppedImageData,test_path_table.Var1,UniformOutput=false);
test_path_table.Num = cellfun(@(x) size(x,1),t);
test_files_path = cat(1,t{:});
t = arrayfun(@originalCroppedImageData,validation_path_table.Var1,UniformOutput=false);
validation_path_table.Num = cellfun(@(x) size(x,1),t);
validation_files_path = cat(1,t{:});
t = arrayfun(@originalCroppedImageData,train_path_table.Var1,UniformOutput=false);
train_files_path = cat(1,t{:});
train_path_table.Num = cellfun(@(x) size(x,1),t);

imdsTest = imageDatastore(test_files_path);
imdsValidation = imageDatastore(validation_files_path);
imdsTrain = imageDatastore(train_files_path);

imdsTest.Labels = categorical(cellfun(@labeling,test_files_path,UniformOutput=false));
imdsValidation.Labels = categorical(cellfun(@labeling,validation_files_path,UniformOutput=false));
imdsTrain.Labels = categorical(cellfun(@labeling,train_files_path,UniformOutput=false));

classNames = categories(imdsTrain.Labels);
numClasses = numel(classNames);

net = imagePretrainedNetwork("googlenet",NumClasses=numClasses);

inputSize = net.Layers(1).InputSize;

learnables = net.Learnables;
numLearnables = size(learnables,1);

for I = 1:numLearnables-10
    Layer_name = learnables.Layer(I);
    Parameter_name = learnables.Parameter(I);
    net = setLearnRateFactor(net,Layer_name,Parameter_name,0);
end

pixelRange = [-10 10];

imageAugmenter = imageDataAugmenter( ...
    RandXReflection=true, ...
    RandYReflection=true, ...
    RandXTranslation=pixelRange, ...
    RandYTranslation=pixelRange);

augimdsTrain = augmentedImageDatastore(inputSize(1:2),imdsTrain, ...
    DataAugmentation=imageAugmenter);

augimdsValidation = augmentedImageDatastore(inputSize(1:2),imdsValidation);

augimdsTest = augmentedImageDatastore(inputSize(1:2),imdsTest);

options = trainingOptions("adam", ...
    MaxEpochs=10, ...
    MiniBatchSize=128, ...
    Shuffle="every-epoch", ...
    ValidationData=augimdsValidation, ...
    ValidationFrequency=2000, ...
    InitialLearnRate=0.001, ...
    Plots="training-progress", ...
    Metrics="accuracy", ...
    Verbose=false);

net = trainnet(augimdsTrain,net,"crossentropy",options);

save(fullfile(".","imds_options_net"),"net","imdsTest","imdsTrain","imdsValidation","options","imageAugmenter");


YTest = minibatchpredict(net,augimdsTest);

writetable(table(imdsTest.Files,imdsTest.Labels,YTest(:,1),YTest(:,2),VariableNames=["Path","Label",classNames{1},classNames{2}]), ...
      fullfile(".","score.csv"));


AIH_prediction = t.AIH > t.DILI;
predicted_label = arrayfun(@my_prediction,AIH_prediction,UniformOutput=false);

sampleIDs = categorical(cellfun(@getSampleID,t.Path,UniformOutput=false));
categories_of_sampleIDs = categories(sampleIDs);

writetable(table(t.Path,t.Label,predicted_label,sampleIDs,t.AIH,t.DILI,VariableNames=["Path","Label","PredictedLabel","ID","AIH_score","DILI_score"]), ...
    fullfile(".","score.csv"));

function sampleID = getSampleID(path)

tree = strsplit(path,filesep);
sampleID = tree{end-4};

end

function label = my_prediction(aih_flag)

if aih_flag
    label = "AIH";
else
    label = "DILI";
end

end

function files = originalCroppedImageData(sampleID)
root = "C:\Users\Public\Documents\AIH_DILI_STUDY\20240929_AI_STUDY";

resolution = "x20" ;
image_size = "224_224" ;

color_change_flag = false ; % 色変換を施した画像は使わずに，元データのみでの学習とする．

if sampleID >= 2000
    class_name = "DILI";
else
    class_name = "AIH";
end

if not(color_change_flag)
    files = struct2table(dir(fullfile(root,class_name,num2str(sampleID),resolution,image_size,class_name,"SmallSize*.jpg")));
    files = fullfile(files.folder,files.name);
else
    files = struct2table(dir(fullfile(root,class_name,num2str(sampleID),resolution,image_size,class_name,"norm3*.jpg")));
    files = fullfile(files.folder,files.name);
end

end

function class = labeling(file_path)
dir_tree = strsplit(file_path,filesep);
class = dir_tree{end-1};
end
