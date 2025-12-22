clear;

df = dir(fullfile(".","**","x20","norm3_SmallSize*_x20_*.jpg"));
df_folder={df.folder}';
df_name={df.name}';


for h=1:size(df,1)

    im =imread(fullfile(df_folder{h},df_name{h}));
    if contains(df_name{h},"norm3")
        fullfile(df_folder{h},df_name{h})
        fullfile(df_folder{h},strrep(strrep(df_name{h},".jpg",".csv"),"norm3_",""))
        label = readmatrix(fullfile(df_folder{h},strrep(strrep(df_name{h},".jpg",".csv"),"norm3_","")));
    else

        label = readmatrix(fullfile(df_folder{h},strrep(df_name{h},".jpg",".csv")));
    end

    outer_index = 10;


    width = 500;
    height = 500;
    ncol = fix(size(im,2)/width);
    nrow = fix(size(im,1)/height);




    for I=1:nrow
        for J=1:ncol

            L = label((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width);
            p = sum((L==outer_index),"all")/width/height;


            if p<0.001


                if contains(df_folder{h},'DILI_AI_STUDY')

                    im2 = im((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width,:);
                    imshow(im2);
                    if not(exist(fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"DILI"),"dir"))
                        mkdir(fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"DILI"));
                    end
                    imwrite(im2,fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"DILI",strcat(strrep(df_name{h},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")));


                else

                    im2 = im((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width,:);

                    imshow(im2);
                    if not(exist(fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"AIH"),"dir"))
                        mkdir(fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"AIH"));
                    end
                    imwrite(im2,fullfile(strrep(df_folder{h},"AI_STUDY","norm3_AI_STUDY"),'500_500',"AIH",strcat(strrep(df_name{h},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")));





                end
            end


        end
    end



end

clear;

df = dir(fullfile(".","**","x20","SmallSize*_x20_*.jpg"));
df_folder={df.folder}';
df_name={df.name}';


for h=1:size(df,1)

    im =imread(fullfile(df_folder{h},df_name{h}));
    if contains(df_name{h},"norm1")
        fullfile(df_folder{h},df_name{h})
        fullfile(df_folder{h},strrep(strrep(df_name{h},".jpg",".csv"),"norm1_",""))
        label = readmatrix(fullfile(df_folder{h},strrep(strrep(df_name{h},".jpg",".csv"),"norm1_","")));
    else

        label = readmatrix(fullfile(df_folder{h},strrep(df_name{h},".jpg",".csv")));
    end

    outer_index = 10;


    width = 500;
    height = 500;
    ncol = fix(size(im,2)/width);
    nrow = fix(size(im,1)/height);




    for I=1:nrow
        for J=1:ncol

            L = label((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width);
            p = sum((L==outer_index),"all")/width/height;


            if p<0.001


                if contains(df_folder{h},'DILI_AI_STUDY')

                    im2 = im((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width,:);
                    imshow(im2);
                    imwrite(im2,fullfile(df_folder{h},'500_500',"DILI",strcat(strrep(df_name{h},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")));


                else

                    im2 = im((I-1)*height+1:(I-1)*height+height,(J-1)*width+1:(J-1)*width+width,:);

                    imshow(im2);
                    imwrite(im2,fullfile(df_folder{h},'500_500',"AIH",strcat(strrep(df_name{h},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")));





                end
            end


        end
    end



end

clear;