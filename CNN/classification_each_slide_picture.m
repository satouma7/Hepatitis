df = dir(fullfile(".","validation"));
df_folder = {df.folder}';
df_name = {df.name}';

%load("nasnet_large_x20_no_nomarization_0.95429_net.mat");

vs_scores = zeros(20,1);

for h = 3:size(df,1)
    test_imds = imageDatastore(fullfile(df_folder{h},df_name{h},"x20","500_500","**","Small*.jpg"),LabelSource="foldernames");
    aug_test_imds = augmentedImageDatastore(net.Layers(1).InputSize(1:2),test_imds);
    [~,scores] = classify(net,aug_test_imds);
    diliscores = sort(scores(:,2));
    diliscores = [diliscores;1];
    widths = diliscores(2:end)-diliscores(1:end-1);
    heights = 1:size(widths,1);
    heights = heights/size(widths,1);
    area = heights*widths; 
    vs_scores(h-2)=area;
    subplot(4,5,h-2);
    hold on
    histo = histogram(scores(:,2),"BinWidth",0.01,"Normalization","cdf",FaceColor=[0.8500 0.3250 0.0980]);
    xlim([0,1]);ylim([0,1]);title(strcat(df_name{h}," ",num2str(area-0.5)));histo.LineStyle = "none";
    grid on;plot([0,1],[0,1],LineStyle="--",LineWidth=1);histo.BinLimits = [0,1];
    hold off
    

end

% test_table = readtable(fullfile("no_norm_AI_STUDY","imds_folder_list","1","test_list.csv"),"Delimiter",',','VariableNamingRule','preserve');
% 
% 
% %load("nasnet_large_x20_no_nomarization_0.95429_net.mat");
% 
% vs_scores = zeros(20,1);
% 
% for h = 1:size(test_table,1)
%     test_imds = imageDatastore(test_table.Var1(h),IncludeSubfolders=true,LabelSource="foldernames");
%     aug_test_imds = augmentedImageDatastore(net.Layers(1).InputSize(1:2),test_imds);
%     [~,scores] = classify(net,aug_test_imds);
%     diliscores = sort(scores(:,2));
%     diliscores = [diliscores;1];
%     widths = diliscores(2:end)-diliscores(1:end-1);
%     heights = 1:size(widths,1);
%     heights = heights/size(widths,1);
%     area = heights*widths; 
%     vs_scores(h)=area;
%     subplot(4,5,h);
%     hold on
%     histo = histogram(scores(:,2),"BinWidth",0.01,"Normalization","cdf",FaceColor=[0.8500 0.3250 0.0980]);
%     xlim([0,1]);ylim([0,1]);title(strcat(test_table.Var2(h)," ",num2str(area-0.5)," ",num2str(numel(test_imds.Files))));histo.LineStyle = "none";
%     grid on;plot([0,1],[0,1],LineStyle="--",LineWidth=1);histo.BinLimits = [0,1];
%     hold off
% 
% 
% end
% 
