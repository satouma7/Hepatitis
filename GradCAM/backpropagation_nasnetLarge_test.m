aih_index = 1;
dili_index = 2;


d = struct2table(dir(fullfile("**","nasnet_large_x20_no_norm_0.87591*mat")));

load(fullfile(d.folder,d.name));
          
test_table = readtable(fullfile(d.folder,"test_list.csv"),"Delimiter",',','VariableNamingRule','preserve');

imds = imageDatastore(test_table.Var1,"IncludeSubfolders",true,"LabelSource","foldernames");


inputSize = net.Layers(1).InputSize(1:2);
classes = net.Layers(end).Classes;

original_im = readimage(imds,600);
im = imresize(original_im,inputSize);


lgraph = layerGraph(net);
lgraph = removeLayers(lgraph,lgraph.Layers(end).Name);

%dlnet = dlnetwork(lgraph);

softmaxName = 'softmax';

dlImg = dlarray(single(im),'SSC');


customRelu = CustomBackpropReluLayer();
customRelu.BackpropMode = "guided-backprop";

lgraphGB = replaceLayersOfType(lgraph, ...
    "nnet.cnn.layer.ReLULayer",customRelu);

dlnetGB = dlnetwork(lgraphGB);


dydIGB = dlfeval(@gradientMap,dlnetGB,dlImg,softmaxName,dili_index);

mapGB = abs(extractdata(dydIGB));
mapGB = rescale(mapGB);
mapGB = 1-mapGB;
mapGB = imresize(mapGB,[size(original_im,1),size(original_im,2)]);

imshow(imfuse(mapGB,im,"blend","Scaling","independent"));


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