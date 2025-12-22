df = dir(fullfile(".","**","all_three_colum_rgb.csv"));
df_folder = {df.folder}';
df_name = {df.name}';


for h =1:size(df,1)

    m = (readmatrix(fullfile(df_folder{h},df_name{h})));
    [~,centers]= kmeans(m,2);
    writematrix(centers,fullfile(df_folder{h},"centers.csv"));


end

clear;