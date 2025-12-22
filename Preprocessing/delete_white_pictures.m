clear;

df = dir(fullfile(".","**","*.jpg"));
df_folder = {df.folder}';
df_name = {df.name}';

for h = 1:size(df,1)
    if contains(df_folder{h},"x20")
        centers = readmatrix(fullfile(df_folder{h},"centers.csv"));
        im = imread(fullfile(df_folder{h},df_name{h}));
        reshaped_im = [reshape(im(:,:,1),[],1),reshape(im(:,:,2),[],1),reshape(im(:,:,3),[],1)];


        [~,outer_index] = max(mean(centers,2));

        k = dsearchn(centers,double(reshaped_im(1:100:end,:)));

        imshow(im);

        xlabel(num2str(double(sum(k==outer_index,"all"))/double(size(k,1))));pause(0.1);

        

        clear("reshaped_im");
        clear("im");
    end
end

clear;