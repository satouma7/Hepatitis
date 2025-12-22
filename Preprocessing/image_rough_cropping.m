clear;

clear;

df = dir(fullfile(".","**","x20","_*i*j*.jpg"));
df_folder = {df.folder}';
df_name = {df.name}';

for h = 1:size(df,1)
    label = readmatrix(fullfile(df_folder{h},strrep(df_name{h},".jpg",".csv")));
    im = imread(fullfile(df_folder{h},df_name{h}));
    c = sum((label==10),1)/size(label,1) < 0.95;
    r = sum((label==10),2)/size(label,2) < 0.95;
    label = label(:,c);
    label = label(r,:);
    im = im(:,c,:);
    im = im(r,:,:);
    imshow(labeloverlay(im,label));pause(1);

    delete(fullfile(df_folder{h},strrep(df_name{h},".jpg",".csv")));
    delete(fullfile(df_folder{h},df_name{h}));

    imwrite(im,fullfile(df_folder{h},strcat("SmallSize",df_name{h})));
    writematrix(label,fullfile(df_folder{h},strcat("SmallSize",strrep(df_name{h},".jpg",".csv"))));

    clear("im");
    clear("label");
end

clear;

