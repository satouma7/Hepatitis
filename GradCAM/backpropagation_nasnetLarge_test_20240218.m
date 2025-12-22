load(fullfile("norm1_AI_STUDY","imds_folder_list","10","nasnet_large_x20_no_norm_0.99855_net.mat"));

test_table = readtable(fullfile("norm1_AI_STUDY","imds_folder_list","10","test_list.csv"),"Delimiter",',','VariableNamingRule','preserve');
no_norm_test_table = strrep(test_table.Var1,"norm1","no_norm");


test_imds = imageDatastore(test_table.Var1,"IncludeSubfolders",true,"LabelSource","foldernames");
no_norm_test_imds = imageDatastore((no_norm_test_table),"IncludeSubfolders",true,"LabelSource","foldernames");


inputSize = net.Layers(1).InputSize(1:2);
classes = net.Layers(end).Classes;

lgraph = layerGraph(net);
lgraph = removeLayers(lgraph,lgraph.Layers(end).Name);

softmaxName = 'softmax';
customRelu = CustomBackpropReluLayer();
customRelu.BackpropMode = "guided-backprop";

lgraphGB = replaceLayersOfType(lgraph, ...
    "nnet.cnn.layer.ReLULayer",customRelu);

cmap =turbo(255);

dlnetGB = dlnetwork(lgraphGB);






for i = 1:numel(test_imds.Labels)

    image_tile = cell(24);


    no_norm_test_img = readimage(no_norm_test_imds,i);
    %norm1_test_img = readimage(test_imds,i);

    sample = strsplit(test_imds.Files{i},filesep);
    sample = sample(8);

    pic_title = strcat(string(sample),"_Predicted_Score_");


    % back propagation
    original_im = no_norm_test_img;
    im = imresize(original_im,inputSize);
    dlImg = gpuArray(dlarray(single(im),'SSC'));


    for j=1:4
        image_tile{1+(j-1)*6}=no_norm_test_img;
        image_tile{4+(j-1)*6}=no_norm_test_img;

        [ypredicted,scores] = classify(net,imresize(no_norm_test_img,net.Layers(1).InputSize(1:2)));
        [score,label_idx]=max(scores);

        pic_title = strcat(pic_title,string(ypredicted));

        pic_title = strcat(pic_title,"_"+num2str(score)+"_");



        dydIGB = dlfeval(@gradientMap,dlnetGB,dlImg,softmaxName,1);
        mapaih = extractdata(dydIGB);
        %mapaih = mapaih.*(mapaih>=0);
        dydIGB = dlfeval(@gradientMap,dlnetGB,dlImg,softmaxName,2);
        mapdili = extractdata(dydIGB);
        %mapdili = mapdili.*(mapdili>=0);

        maxdili = max(mapdili,[],"all");
        maxaih = max(mapaih,[],"all");
        mindili = min(mapdili,[],"all");
        minaih = min(mapaih,[],"all");

        M = max(maxaih,maxdili);
        m = min(minaih,mindili);

        grad_map_aih = rescale(gradCAM(net,dlImg,"AIH"));
        grad_map_dili = rescale(gradCAM(net,dlImg,"DILI"));

        image_tile{2+(j-1)*6} = 1/(M-m)*(mapaih-m);
        image_tile{3+(j-1)*6} = 1/(M-m)*(mapdili-m);

        mapaih = mapaih.*grad_map_aih;
        mapdili = mapdili.*grad_map_dili;

        maxdili = max(mapdili,[],"all");
        maxaih = max(mapaih,[],"all");
        mindili = min(mapdili,[],"all");
        minaih = min(mapaih,[],"all");

        M = max(maxaih,maxdili);
        m = min(minaih,mindili);

        image_tile{5+(j-1)*6} = 1/(M-m)*(mapaih-m);
        image_tile{6+(j-1)*6} = 1/(M-m)*(mapdili-m);


        %norm1_test_img = rot90(norm1_test_img);
        no_norm_test_img = rot90(no_norm_test_img);
        dlImg = rot90(dlImg);

    end

    if test_imds.Labels(i) == 'DILI'
        imwrite(imtile(image_tile,"GridSize",[4,6],"BorderSize",10),fullfile("20240221","DILI",num2str(i)+"_"+strcat(pic_title,".jpg")));

    else
        imwrite(imtile(image_tile,"GridSize",[4,6],"BorderSize",10),fullfile("20240221","AIH",num2str(i)+"_"+strcat(pic_title,".jpg")));


    end

    clear("dydIGB");

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