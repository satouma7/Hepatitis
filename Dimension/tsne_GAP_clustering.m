
%imds_options_net.mat をロードする
load(fullfile(""));

%classes = net.Layers(end).Classes;

mbq = minibatchqueue(imdsTest,1,"PartialMiniBatch","return","MiniBatchSize",128,"MiniBatchFcn",@preprocessMinibatch);

Y = minibatchpredict(net,mbq,"Outputs",'pool5-7x7_s1');
Y = squeeze(Y);
Y = extractdata(Y);
writematrix(Y,fullfile("C:\Users\Public\Documents\AIH_DILI_STUDY\source\google_net_deep_learning\2025-04-12","GAP_layer_vector.csv"));


points = tsne(Y',"Distance","cosine");

T =strrep(imdsTest.Folders,".","");
t = split(T,filesep);
t = t(:,8);
cmap = jet(size(imdsTest.Folders,1));

for j=1:size(t,1)
    figure(Color=[1,1,1],Position=[0,0,1200,1200]);
    hold on
    for i = 1:size(imdsTest.Folders,1)
        idx = contains(imdsTest.Files,T(i));
        if t(i)== string(t(j))
            scatter(points(idx,1),points(idx,2),36,"black",LineWidth=2);
        else
            scatter(points(idx,1),points(idx,2),9,cmap(i,:),LineWidth=0.5);
        end
    end
    grid on
    legend(t);
    hold off
end


function newImage = preprocessMinibatch(image)
newImage = cat(4,image{:});
newImage = rescale(newImage,"InputMin",0,"InputMax",255);
end