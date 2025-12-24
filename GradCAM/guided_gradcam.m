good_score_id_AIH = ["\1047\"];
good_score_id_DILI = ["\2141\"];

%imds_options_net.mat をロードする
load(fullfile(""));

AIH_id_idx = cellfun(@(path)contains(path,good_score_id_AIH),imdsTest.Files);
DILI_id_idx = cellfun(@(path)contains(path,good_score_id_DILI),imdsTest.Files);

good_score_imds = imageDatastore(imdsTest.Files(or(AIH_id_idx,DILI_id_idx)));
good_score_imds.Labels = imdsTest.Labels(or(AIH_id_idx,DILI_id_idx));

inputSize = net.Layers(1).InputSize(1:2);
dlnetGB = net;

softmaxName = 'prob';
customRelu = CustomBackpropReluLayer();
customRelu.BackpropMode = "guided-backprop";

dlnetGB = replaceLayersOfType(dlnetGB, ...
    "nnet.cnn.layer.ReLULayer",customRelu);


dlnetGB = removeLayers(dlnetGB,'pool5-drop_7x7_s1');
dlnetGB = connectLayers(dlnetGB,'pool5-7x7_s1','loss3-classifier');
dlnetGB = initialize(dlnetGB);

cmap = turbo(255);


classLabel = ["AIH","DILI"];

for i = 1:size(good_score_imds.Files,1)
    file_path = string(good_score_imds.Files{i});
    file_path = split(file_path,filesep);
    if not(exist(fullfile(join(file_path(1:6),filesep),"gradCAM_guidedBackPropagation"),"dir"))
        mkdir(fullfile(join(file_path(1:6),filesep),"gradCAM_guidedBackPropagation"));
    end
    image = imread(good_score_imds.Files{i});
    X = dlarray(single(image));
    score = minibatchpredict(dlnetGB,X); 
    new_image_file = fullfile(join(file_path(1:6),filesep),"gradCAM_guidedBackPropagation",strcat(num2str(score(1)),"_",strcat(num2str(score(2)),"_",file_path(12))));
    AIH_dydIGB = dlfeval(@gradientMap,dlnetGB,X,softmaxName,1);
    AIH_mapGB = sum(abs(extractdata(AIH_dydIGB)),3);
    AIH_score_CAM = gradCAM(dlnetGB,image,1,ReductionLayer='prob',FeatureLayer='inception_5b-output');
    AIH_mapGB = rescale(AIH_mapGB);
    AIH_score_CAM = rescale(AIH_score_CAM);
    AIH_grad_GB_map = rescale(AIH_mapGB .* AIH_score_CAM);

    DILI_dydIGB = dlfeval(@gradientMap,dlnetGB,X,softmaxName,2);
    DILI_mapGB = sum(abs(extractdata(DILI_dydIGB)),3);
    DILI_score_CAM = gradCAM(dlnetGB,image,2,ReductionLayer='prob',FeatureLayer='inception_5b-output');
    DILI_mapGB = rescale(DILI_mapGB);
    DILI_score_CAM = rescale(DILI_score_CAM);
    DILI_grad_GB_map = rescale(DILI_mapGB .* DILI_score_CAM);

    turbo_AIH_mapGB = ind2rgb(uint8(floor(AIH_mapGB*255)),cmap);
    turbo_AIH_score_CAM = ind2rgb(uint8(floor(AIH_score_CAM*255)),cmap);
    turbo_AIH_grad_GB_map = ind2rgb(uint8(floor(AIH_grad_GB_map*255)),cmap);

    turbo_DILI_mapGB = ind2rgb(uint8(floor(DILI_mapGB*255)),cmap);
    turbo_DILI_score_CAM = ind2rgb(uint8(floor(DILI_score_CAM*255)),cmap);
    turbo_DILI_grad_GB_map = ind2rgb(uint8(floor(DILI_grad_GB_map*255)),cmap);

    image_tile = imtile({image,turbo_AIH_score_CAM,image,turbo_DILI_score_CAM, ...
        image,turbo_AIH_mapGB,image,turbo_DILI_mapGB, ...
        image,turbo_AIH_grad_GB_map,image,turbo_DILI_grad_GB_map},[3,4]);

    imshow(image_tile);

    imwrite(image_tile,new_image_file);

end

function lgraph = replaceLayersOfType(lgraph, layerType, newLayer)
% Replace layers in the layerGraph lgraph of the type specified by
% layerType with copies of the layer newLayer.

for i=1:length(lgraph.Layers)
    if isa(lgraph.Layers(i), layerType)
        % Match names between old and new layer.
        layerName = lgraph.Layers(i).Name;
        newLayer.Name = layerName;

        lgraph = replaceLayer(lgraph, layerName, newLayer);
    end
end
end

function dydI = gradientMap(dlnet, dlImgs, softmaxName, classIdx)
% Compute the gradient of a class score with respect to one or more input
% images.

dydI = dlarray(zeros(size(dlImgs)));

for i=1:size(dlImgs,4)
    I = dlImgs(:,:,:,i);
    scores = predict(dlnet,I,'Outputs',{softmaxName});
    classScore = scores(classIdx);
    dydI(:,:,:,i) = dlgradient(classScore,I);
end
end