classdef NAZNdpiFilesManagement < handle % handle継承すると参照型のオブジェクトとなる
    properties
        ndpi_files_path = ""
        document_path = ""
        classes
        ndpisplit_path = ""
        standard_path = ""
        file_properties_root
        file_properties
        x20_magnification_flag = true;
        x40_magnification_flag = false;
        process
        width
        height
        stop_flag

    end
    methods
        function obj = NAZNdpiFilesManagement(dir_path,class_names,ndpisplit_path,standard_path,width,height)
            obj.ndpi_files_path = dir_path;
            obj.standard_path = standard_path;
            obj.width = width;
            obj.height = height;

            if size(class_names,2)>1
                for I = 1:size(class_names,2)
                    obj.stop_flag = true;
                    if not(exist(fullfile(dir_path,class_names(I)),"dir"))
                        obj.stop_flag = false;
                    end
                end
            elseif size(class_name,2)==1
                obj.stop_flag = true;
                if not(exist(fullfile(dir_path,class_names),"dir"))
                    obj.stop_flag = false;
                end
            else
                obj.stop_flag = false;
            end

            if not(exist(fullfile(dir_path,"doc"),"dir"))
                mkdir(fullfile(dir_path,"doc"));
                obj.file_properties_root = fullfile(dir_path,"doc");
            elseif exist(fullfile(dir_path,"doc","properties.csv"),"file")
                obj.file_properties_root = fullfile(dir_path,"doc");
                obj.file_properties = readtable(fullfile(dir_path,"doc","properties.csv"));
            else
                obj.file_properties_root = fullfile(dir_path,"doc");
            end

            obj.document_path = fullfile(dir_path,"doc");

            obj.classes = class_names;
            obj.ndpisplit_path = ndpisplit_path;
        end
        function getFileProperties(obj)
            if exist(fullfile(obj.document_path,"properties.csv"),"file")
                obj.file_properties = readtable(fullfile(obj.document_path,"properties.csv"));
            end
        end
        function writeFileProperties(obj)
            writetable(obj.file_properties,fullfile(obj.document_path,"properties.csv"));
        end
        function WritingCSVFileToMatch(obj)
            dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,"**","*.ndpi")));
            id = zeros(size(dir_table,1),1);
            for I = 1:size(obj.classes,2)
                id = id +(cellfun(@extractClassName,dir_table.folder,UniformOutput=false) == obj.classes(I)) * I * 1000 ;
            end   
            id = id + (1:size(id,1))';
            writetable(table(fullfile(dir_table.folder,dir_table.name),num2str(id)),fullfile(obj.document_path,'taiouhyou.csv'));
            
            function class = extractClassName(folder_path)
                tree_structure = strsplit(folder_path,filesep);
                class = tree_structure{end};
            end
        end
        function RenameNdpiFiles(obj)
            dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,"**","*.ndpi")));
            matching_table = readtable(fullfile(obj.document_path,"taiouhyou.csv"),"Delimiter",',','VariableNamingRule','preserve');

            new_files = cell(size(dir_table,1),1);


            try
                if size(dir_table,1)>1
                    for I = 1:size(dir_table,1)
                        old_file = fullfile(dir_table.folder{I},dir_table.name{I});
                        for J = 1:size(matching_table,1)
                            if matching_table.Var1{J} == string(old_file)

                                new_file = fullfile(dir_table.folder{I},num2str(matching_table.Var2(J)),"_"+num2str(matching_table.Var2(J))+".ndpi");
                                new_file_folder = fullfile(dir_table.folder{I},num2str(matching_table.Var2(J)));
                                new_files{I} = new_file;
                            end
                        end
                        if not(exist(new_file_folder,"dir"))
                            mkdir(new_file_folder);
                        end
                        movefile(old_file,new_file);
                    end
                elseif size(dir_table,1)==1
                    old_file = fullfile(dir_table.folder,dir_table.name);
                    new_file_folder = fullfile(dir_table.folder,num2str(matching_table.Var2));
                    new_file = fullfile(dir_table.folder,num2str(matching_table.Var2),"_"+num2str(matching_table.Var2)+".ndpi");
                    new_files{1} = new_file;
                    if not(exist(new_file_folder,"dir"))
                        mkdir(new_file_folder);
                    end
                    movefile(old_file,new_file);

                end
            catch error
                error.message
            end

            makeRGBCsvFile = logical(zeros(size(dir_table,1),1));
            kmeans = logical(zeros(size(dir_table,1),1));
            makeLabel = logical(zeros(size(dir_table,1),1));
            PCA = logical(zeros(size(dir_table,1),1));
            roughCropping = logical(zeros(size(dir_table,1),1));
            Cropping = logical(zeros(size(dir_table,1),1));

            files = new_files;

            obj.file_properties = table(files,makeRGBCsvFile,kmeans,makeLabel,PCA,roughCropping,Cropping);
            writetable(obj.file_properties,fullfile(obj.file_properties_root,"properties.csv"));


        end
        function makeSubfolders(obj)
            size_folder_name = num2str(obj.height)+"_" + num2str(obj.width);
            class = obj.classes;
            try
                for dir_idx = 1:size(class,2)
                    dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,class(dir_idx),"**","*.ndpi")));
                    if size(dir_table,1)>1
                        for I = 1:size(dir_table,1)
                            mkdir(dir_table.folder{I},fullfile("x40",size_folder_name,class(dir_idx)));
                            mkdir(dir_table.folder{I},fullfile("x20",size_folder_name,class(dir_idx)));
                        end
                    elseif size(dir_table,1)==1
                        mkdir(dir_table.folder,fullfile("x40",size_folder_name,class(dir_idx)));
                        mkdir(dir_table.folder,fullfile("x20",size_folder_name,class(dir_idx)));

                    end
                end
            catch error
                error.message
            end
        end
        function makeBatchFile(obj)
            dir_table =struct2table(dir(fullfile(obj.ndpi_files_path,"**","*.ndpi")));
            try

                fid = fopen(fullfile(obj.document_path,'split.bat'),'wt'); % 書き込み用にファイルオープン

                if size(dir_table,1)>1

                    for I = 1:size(dir_table,1)
                        str = {fullfile(obj.ndpisplit_path,'ndpisplit.exe'),'-O',fullfile(dir_table.folder{I},'x40'),'-M400J100','-x40',fullfile(dir_table.folder{I},dir_table.name{I})};
                        fprintf(fid,"%s %s %s %s %s %s\n",str{:}); % 文字列の書き出し
                        str = {fullfile(obj.ndpisplit_path,'ndpisplit.exe'),'-O',fullfile(dir_table.folder{I},'x20'),'-M400J100','-x20',fullfile(dir_table.folder{I},dir_table.name{I})};
                        fprintf(fid,"%s %s %s %s %s %s\n",str{:}); % 文字列の書き出し
                    end
                    fclose(fid); % ファイルクローズ

                elseif size(dir_table,1)==1
                    str = {fullfile(obj.ndpisplit_path,'ndpisplit.exe'),'-O',fullfile(dir_table.folder,'x40'),'-M400J100','-x40',fullfile(dir_table.folder,dir_table.name)};
                    fprintf(fid,"%s %s %s %s %s %s\n",str{:}); % 文字列の書き出し
                    str = {fullfile(obj.ndpisplit_path,'ndpisplit.exe'),'-O',fullfile(dir_table.folder,'x20'),'-M400J100','-x20',fullfile(dir_table.folder,dir_table.name)};
                    fprintf(fid,"%s %s %s %s %s %s\n",str{:}); % 文字列の書き出し
                    fclose(fid); % ファイルクローズ
                end

            catch error
                error.message
                try
                    fclose(fid);
                catch
                end
            end
        end
        function executeBatchFile(obj)
            if exist(fullfile(obj.document_path,"split.bat"),"file")
                system(fullfile(obj.document_path,"split.bat"));
            end
        end
        function kmeans(obj,file_path)
            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});
            dir_table = struct2table(dir(fullfile(folder,"x*","*_z0_*.jpg")));
            image_data = [];
            try
                for J = 1:size(dir_table,1)
                    im = imread(fullfile(dir_table.folder{J},dir_table.name{J}));
                    %imshow(im);
                    column_im(:,1) = reshape(im(:,:,1),[],1);
                    column_im(:,2) = reshape(im(:,:,2),[],1);
                    column_im(:,3) = reshape(im(:,:,3),[],1);
                    image_data = [image_data;column_im(1:64:end,:)];
                end
                [~,centers]= kmeans(double(image_data),2);
                writematrix(centers,fullfile(folder,"centers.csv"));
            catch error
                error.message
            end
        end
        function out = makeLabel(obj,file_path)
            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});
            dir_table = struct2table(dir(fullfile(folder,"x*","*.jpg")));
            outer_deleted_image_data = [];
            if size(dir_table,1)>1
                centers = readmatrix(fullfile(folder,"centers.csv"));
                try
                    for J = 1:size(dir_table,1)
                        im =imread(fullfile(dir_table.folder{J},dir_table.name{J}));
                        reshaped_im = [reshape(im(:,:,1),[],1),reshape(im(:,:,2),[],1),reshape(im(:,:,3),[],1)];
                        [~,outer_index] = max(mean(centers,2));
                        k = my_dsearchn(centers,double(reshaped_im));
                        label = reshape(k,size(im,1),size(im,2));
                        BW = not(label ==outer_index);%tissue is equal to 1
                        BW2 = (imfill(BW,"hole"));%outer region is equal to 0
                        BW = uint8(abs(BW-BW2));%white region in tissue is eqaul to 1
                        label = uint8(label);
                        label = label.*(uint8(not((BW))))+(uint8(BW))*20;%white region index in tissue = 20
                        label = label.*(uint8(BW2))+(uint8(not((BW2))))*10;%outer region index in tissue = 10
                        outer_index=10;
                        tentative_reshaped_im = (reshaped_im(logical(reshape((not(label == outer_index).*not(label == 20)),[],1)),:)');
                        tentative_reshaped_im = tentative_reshaped_im(:,1:6:end);
                        if sum(label == outer_index,"all")/size(im,1)/size(im,2) <0.9
                            % writematrix(label,strrep (fullfile(dir_table.folder{J},dir_table.name{J}),".jpg",".csv"));
                            outer_deleted_image_data = [outer_deleted_image_data;tentative_reshaped_im'];
                            [im,label] = roughCropping(im,label);
                            delete(fullfile(dir_table.folder{J},dir_table.name{J}));
                            imwrite(im,fullfile(dir_table.folder{J},strcat("SmallSize",dir_table.name{J})));
                            writematrix(label,fullfile(dir_table.folder{J},strcat("SmallSize",strrep(dir_table.name{J},".jpg",".csv"))));
                        else
                            delete(fullfile(dir_table.folder{J},dir_table.name{J}));
                        end
                    end
                catch error
                    error.message
                end
            elseif size(dir_table,1)==1
                centers = readmatrix(fullfile(folder,"centers.csv"));
                try
                    for J = 1:size(dir_table,1)
                        im =imread(fullfile(dir_table.folder,dir_table.name));
                        reshaped_im = [reshape(im(:,:,1),[],1),reshape(im(:,:,2),[],1),reshape(im(:,:,3),[],1)];
                        [~,outer_index] = max(mean(centers,2));
                        k = my_dsearchn(centers,double(reshaped_im));
                        label = reshape(k,size(im,1),size(im,2));
                        BW = not(label ==outer_index);%tissue is equal to 1
                        BW2 = (imfill(BW,"hole"));%outer region is equal to 0
                        BW = uint8(abs(BW-BW2));%white region in tissue is eqaul to 1
                        label = uint8(label);
                        label = label.*(uint8(not((BW))))+(uint8(BW))*20;%white region index in tissue = 20
                        label = label.*(uint8(BW2))+(uint8(not((BW2))))*10;%outer region index in tissue = 10
                        outer_index=10;
                        tentative_reshaped_im = (reshaped_im(logical(reshape((not(label == outer_index).*not(label == 20)),[],1)),:)');
                        tentative_reshaped_im = tentative_reshaped_im(:,1:6:end);
                        if sum(label == outer_index,"all")/size(im,1)/size(im,2) <0.9
                            % writematrix(label,strrep (fullfile(dir_table.folder,dir_table.name),".jpg",".csv"));
                            outer_deleted_image_data = [outer_deleted_image_data;tentative_reshaped_im'];
                            [im,label] = roughCropping(im,label);
                            delete(fullfile(dir_table.folder,dir_table.name));
                            imwrite(im,fullfile(dir_table.folder,strcat("SmallSize",dir_table.name)));
                            writematrix(label,fullfile(dir_table.folder,strcat("SmallSize",strrep(dir_table.name,".jpg",".csv"))));
                        else
                            delete(fullfile(dir_table.folder,dir_table.name));
                        end
                    end
                catch error
                    error.message
                end
            end
            out = outer_deleted_image_data;
            function k = my_dsearchn(centers,PQ)
                c_c = mean(centers,1);
                new_PQ = [PQ,ones(size(PQ,1),1)];
                vec_t = centers(1,:)-centers(2,:);
                flag = sum(new_PQ*[1,0,0,0;0,1,0,0;0,0,1,0;-c_c,1].*[vec_t,0],2);
                flag1 = sum([centers(1,:),1]*[1,0,0,0;0,1,0,0;0,0,1,0;-c_c,1].*[vec_t,0],2)>0;
                flag2 = sum([centers(2,:),1]*[1,0,0,0;0,1,0,0;0,0,1,0;-c_c,1].*[vec_t,0],2)>0;
                k = uint8((flag > 0) == flag1) + uint8((flag > 0) == flag2)*2;
            end
            function [new_im,new_label] = roughCropping(im,label)
                tentative_im = im;
                tentative_label = label;
                c = sum((label==10),1)/size(label,1) < 0.95;
                r = sum((label==10),2)/size(label,2) < 0.95;
                tentative_label = tentative_label(:,c);
                tentative_label = tentative_label(r,:);
                tentative_im = tentative_im(:,c,:);
                tentative_im = tentative_im(r,:,:);
                new_im = tentative_im;
                new_label = tentative_label;
            end
        end
        function PCA(obj,file_path,outer_delete_image_data)
            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});
            if size(outer_delete_image_data,1)>0
                if size(outer_delete_image_data,1)>0
                    exchange_matrix = pca(double(outer_delete_image_data));
                    writematrix(exchange_matrix,fullfile(folder,"exchange_matrix.csv"));
                    GMModel = fitgmdist( double(outer_delete_image_data)*exchange_matrix,1);
                    writematrix(GMModel.mu,fullfile(folder,"gmmodel_mu.csv"));
                    writematrix(GMModel.Sigma,fullfile(folder,"gmmodel_sigma.csv"));
                end
                % delete(fullfile(dir_table.folder,dir_table.name));
                % for I = 1:size(obj.file_properties,1)
                %     if string(obj.file_properties.files{I}) == string(file_path)
                %         properties = obj.file_properties;
                %         properties.PCA(I) = true;
                %     end
                % end
                % obj.file_properties = properties;
            end
        end
        function normalization(obj,file_path)
            outer_index = 10;
            white_region_in_tissue = 20;

            if exist(fullfile(obj.standard_path,"standard_exchange_matrix.csv"),"file")
                exchange_matrix1 = readmatrix(fullfile(obj.standard_path,"standard_exchange_matrix.csv"),ExpectedNumVariables=3);
            end
            if exist(fullfile(obj.standard_path,"standard_gmmodel_mu.csv"),"file")
                mu1 = readmatrix(fullfile(obj.standard_path,"standard_gmmodel_mu.csv"),ExpectedNumVariables=3);
            end
            if exist(fullfile(obj.standard_path,"standard_gmmodel_sigma.csv"),"file")
                sigma1 = readmatrix(fullfile(obj.standard_path,"standard_gmmodel_sigma.csv"),ExpectedNumVariables=3);
            end

            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});


            if exist(fullfile(folder,"gmmodel_sigma.csv"),"file")>0 && ...
                    exist(fullfile(folder,"gmmodel_mu.csv"),"file")>0 && ...
                    exist(fullfile(folder,"exchange_matrix.csv"),"file")>0
                dir_table = struct2table(dir(fullfile(folder,"x*0","Small*_x*0_*.jpg")));

                exchange_matrix2 = readmatrix(fullfile(folder,"exchange_matrix.csv"));
                mu2 = readmatrix(fullfile(folder,"gmmodel_mu.csv"));
                sigma2 = readmatrix(fullfile(folder,"gmmodel_sigma.csv"));

                if size(dir_table,1)>1
                    for I = 1:size(dir_table,1)
                        im2 = imread(fullfile(dir_table.folder{I},dir_table.name{I}));
                        label2 = readmatrix(fullfile(dir_table.folder{I},strrep(dir_table.name{I},".jpg",".csv")));
                        tentative_im2(:,1) = reshape(im2(:,:,1),[],1);
                        tentative_im2(:,2) = reshape(im2(:,:,2),[],1);
                        tentative_im2(:,3) = reshape(im2(:,:,3),[],1);
                        nrow = size(im2,1);
                        ncol = size(im2,2);
                        tentative_im2 = double(tentative_im2)*exchange_matrix2;
                        normalized_tentative_im2 = (double(tentative_im2)-mu2)*inv(chol(sigma2));
                        modified_tentative_im2 = normalized_tentative_im2*chol(sigma1)+mu1;
                        modified_tentative_im2 =  modified_tentative_im2 * inv(exchange_matrix1);
                        modified_tentative_im2(:,1) = modified_tentative_im2(:,1).*(modified_tentative_im2(:,1)>=0);
                        modified_tentative_im2(:,1) = modified_tentative_im2(:,1).*(modified_tentative_im2(:,1)<=255)+(modified_tentative_im2(:,1)>255)*255;
                        modified_tentative_im2(:,2) = modified_tentative_im2(:,2).*(modified_tentative_im2(:,2)>=0);
                        modified_tentative_im2(:,2) = modified_tentative_im2(:,2).*(modified_tentative_im2(:,2)<=255)+(modified_tentative_im2(:,2)>255)*255;
                        modified_tentative_im2(:,3) = modified_tentative_im2(:,3).*(modified_tentative_im2(:,3)>=0);
                        modified_tentative_im2(:,3) = modified_tentative_im2(:,3).*(modified_tentative_im2(:,3)<=255)+(modified_tentative_im2(:,3)>255)*255;
                        modified_im2(:,:,1) = reshape(modified_tentative_im2(:,1),nrow,ncol);
                        modified_im2(:,:,2) = reshape(modified_tentative_im2(:,2),nrow,ncol);
                        modified_im2(:,:,3) = reshape(modified_tentative_im2(:,3),nrow,ncol);
                        modified_im2 = uint8(fix(modified_im2)).*uint8(not(label2==outer_index)).*uint8(not(label2==white_region_in_tissue));
                        modified_im2 = im2.*uint8(label2==outer_index) + modified_im2;
                        modified_im2 = im2.*uint8(label2==white_region_in_tissue) + modified_im2;
                        imwrite(modified_im2,fullfile(dir_table.folder{I},strcat("norm3_",dir_table.name{I})));
                        clear("tentative_im2");
                        clear("modified_im2");
                    end
                elseif size(dir_table,1) ==1
                    im2 = imread(fullfile(dir_table.folder,dir_table.name));
                    label2 = readmatrix(fullfile(dir_table.folder,strrep(dir_table.name,".jpg",".csv")));
                    tentative_im2(:,1) = reshape(im2(:,:,1),[],1);
                    tentative_im2(:,2) = reshape(im2(:,:,2),[],1);
                    tentative_im2(:,3) = reshape(im2(:,:,3),[],1);
                    nrow = size(im2,1);
                    ncol = size(im2,2);
                    tentative_im2 = double(tentative_im2)*exchange_matrix2;
                    normalized_tentative_im2 = (double(tentative_im2)-mu2)*inv(chol(sigma2));
                    modified_tentative_im2 = normalized_tentative_im2*chol(sigma1)+mu1;
                    modified_tentative_im2 =  modified_tentative_im2 * inv(exchange_matrix1);
                    modified_tentative_im2(:,1) = modified_tentative_im2(:,1).*(modified_tentative_im2(:,1)>=0);
                    modified_tentative_im2(:,1) = modified_tentative_im2(:,1).*(modified_tentative_im2(:,1)<=255)+(modified_tentative_im2(:,1)>255)*255;
                    modified_tentative_im2(:,2) = modified_tentative_im2(:,2).*(modified_tentative_im2(:,2)>=0);
                    modified_tentative_im2(:,2) = modified_tentative_im2(:,2).*(modified_tentative_im2(:,2)<=255)+(modified_tentative_im2(:,2)>255)*255;
                    modified_tentative_im2(:,3) = modified_tentative_im2(:,3).*(modified_tentative_im2(:,3)>=0);
                    modified_tentative_im2(:,3) = modified_tentative_im2(:,3).*(modified_tentative_im2(:,3)<=255)+(modified_tentative_im2(:,3)>255)*255;
                    modified_im2(:,:,1) = reshape(modified_tentative_im2(:,1),nrow,ncol);
                    modified_im2(:,:,2) = reshape(modified_tentative_im2(:,2),nrow,ncol);
                    modified_im2(:,:,3) = reshape(modified_tentative_im2(:,3),nrow,ncol);
                    modified_im2 = uint8(fix(modified_im2)).*uint8(not(label2==outer_index)).*uint8(not(label2==white_region_in_tissue));
                    modified_im2 = im2.*uint8(label2==outer_index) + modified_im2;
                    modified_im2 = im2.*uint8(label2==white_region_in_tissue) + modified_im2;
                    imwrite(modified_im2,fullfile(dir_table.folder,strcat("norm3_",dir_table.name)));
                    clear("tentative_im2");
                    clear("modified_im2");
                end
            end
        end
        function Cropping(obj,file_path)
            size_folder_name = num2str(obj.height)+"_" + num2str(obj.width);
            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});
            dir_table = struct2table(dir(fullfile(folder,"x*","*SmallSize*_x*_*.jpg")));
            class_name = string(tree_structure{end-2});
            if size(dir_table,1)>1
                for idx=1:size(dir_table,1)
                    im =imread(fullfile(dir_table.folder{idx},dir_table.name{idx}));
                    if contains(dir_table.name{idx},"norm3")
                        label = readmatrix(fullfile(dir_table.folder{idx},strrep(strrep(dir_table.name{idx},".jpg",".csv"),"norm3_","")));
                    else
                        label = readmatrix(fullfile(dir_table.folder{idx},strrep(dir_table.name{idx},".jpg",".csv")));
                    end
                    label = makeImageRough(label,5,0.1);
                    outer_index = 10;
                    white_in_tissue = 20;
                    ncol = fix(size(im,2)/obj.width);
                    nrow = fix(size(im,1)/obj.height);
                    for I=1:nrow
                        for J=1:ncol
                            L = label((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width);
                            p = sum(L==outer_index,"all")/obj.width/obj.height;
                            p_white_in_tissue = sum(L==white_in_tissue,"all")/obj.width/obj.height;
                            if p==0 && p_white_in_tissue<0.999
                                for class_idx = 1:size(obj.classes,2)
                                    if class_name == obj.classes(class_idx)
                                        im2 = im((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width,:);
                                        imwrite(im2,fullfile(dir_table.folder{idx},size_folder_name,obj.classes(class_idx),strcat(strrep(dir_table.name{idx},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")))
                                    end
                                end
                            end
                        end
                    end
                end
            elseif size(dir_table,1)==1
                im =imread(fullfile(dir_table.folder,dir_table.name));
                if contains(dir_table.name,"norm3")
                    label = readmatrix(fullfile(dir_table.folder,strrep(strrep(dir_table.name,".jpg",".csv"),"norm3_","")));
                else
                    label = readmatrix(fullfile(dir_table.folder,strrep(dir_table.name,".jpg",".csv")));
                end
                label = makeImageRough(label,5,0.1);
                outer_index = 10;
                white_in_tissue = 20;
                ncol = fix(size(im,2)/obj.width);
                nrow = fix(size(im,1)/obj.height);
                for I=1:nrow
                    for J=1:ncol
                        L = label((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width);
                        p = sum(L==outer_index,"all")/obj.width/obj.height;
                        p_white_in_tissue = sum(L==white_in_tissue,"all")/obj.width/obj.height;
                        if p==0 && p_white_in_tissue<0.999
                            for class_idx = 1:size(obj.classes,2)
                                if class_name == obj.classes(class_idx)
                                    im2 = im((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width,:);
                                    imwrite(im2,fullfile(dir_table.folder,size_folder_name,obj.classes(class_idx),strcat(strrep(dir_table.name,".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")))
                                end
                            end
                        end
                    end
                end
            end
            % for I = 1:size(obj.file_properties,1)
            %     if string(obj.file_properties.files{I}) == string(file_path)
            %         properties = obj.file_properties;
            %         properties.Cropping(I) = true;
            %     end
            % end
            % obj.file_properties = properties;
        end
        function deleteCsvAndTiff(obj,file_path)
            tree_structure = strsplit(string(file_path),filesep);
            folder = fullfile(tree_structure{1:end-1});
            name = tree_structure{end};
            try
                zip(fullfile(folder,strrep(name,".ndpi","_x40_label")),"*.csv",fullfile(folder,"x40"));
            catch error
                error.message
            end
            try
                zip(fullfile(folder,strrep(name,".ndpi","_x20_label")),"*.csv",fullfile(folder,"x20"));
            catch error
                error.message
            end
            try
                dir_table = struct2table(dir(fullfile(folder,"x*","*.csv")));
                if size(dir_table,1)>0
                    if size(dir_table,1)>1
                        for I = 1:size(dir_table,1)
                            delete(fullfile(dir_table.folder{I},dir_table.name{I}));
                        end
                    elseif size(dir_table,1)==1
                        delete(fullfile(dir_table.folder,dir_table.name));
                    end
                end
            catch error
                error.message
            end

            try
                dir_table = struct2table(dir(fullfile(folder,"x*","*.tif")));
                if size(dir_table,1)>0
                    if size(dir_table,1)>1
                        for I = 1:size(dir_table,1)
                            delete(fullfile(dir_table.folder{I},dir_table.name{I}));
                        end
                    elseif size(dir_table,1)==1
                        delete(fullfile(dir_table.folder,dir_table.name));
                    end
                end
            catch error
                error.message
            end
            try
                delete(file_path);
            catch error
                error.message
            end
        end
        function init(obj)
            if obj.stop_flag
                obj.getFileProperties;
                obj.WritingCSVFileToMatch;
                obj.RenameNdpiFiles;
                obj.makeSubfolders;
                obj.makeBatchFile;
                obj.executeBatchFile;
            else
                "フォルダ名がよくないです"
            end
        end
        function run(obj)
            if obj.stop_flag
                obj.getFileProperties;
                if size(obj.file_properties,1) > 1
                    for I = 1:size(obj.file_properties,1)
                        try
                            obj.kmeans(obj.file_properties.files{I});
                            obj.PCA(obj.file_properties.files{I},obj.makeLabel(obj.file_properties.files{I}));
                        catch error
                            error.message
                        end
                        try
                            obj.normalization(obj.file_properties.files{I});
                            obj.Cropping(obj.file_properties.files{I});
                        catch error
                            error.message
                        end
                        obj.deleteCsvAndTiff(obj.file_properties.files{I});
                    end
                elseif size(obj.file_properties,1) == 1
                    try
                        obj.kmeans(obj.file_properties.files);
                        obj.PCA(obj.file_properties.files,obj.makeLabel(obj.file_properties.files));
                    catch error
                        error.message
                    end
                    try
                        obj.normalization(obj.file_properties.files);
                        obj.Cropping(obj.file_properties.files);
                    catch error
                        error.message
                    end
                    obj.deleteCsvAndTiff(obj.file_properties.files);
                end
            else
                "フォルダ名がよくないです"
            end
            obj.result;
        end
        function result(obj)
            if obj.stop_flag
                files_num_on_each_class_x20 = [];
                folders_path = [];
                for I = 1:size(obj.classes,2)
                    dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,obj.classes(I))));
                    files_num = zeros(size(dir_table,1)-2,1);
                    for J = 3:size(dir_table,1)
                        files_num(J-2) = size(struct2table(dir(fullfile(dir_table.folder{J},dir_table.name{J},"x20","**",obj.classes(I),"*.jpg"))),1);
                    end
                    files_num_on_each_class_x20 = [files_num_on_each_class_x20;files_num];
                    folders_path = [folders_path;dir_table.folder(3:end) + "\" + dir_table.name(3:end)];
                end
                writetable(table(folders_path,files_num_on_each_class_x20,VariableNames=["PATH","NUM"]),fullfile(obj.document_path,"x20_number_of_files.csv"));

                files_num_on_each_class_x20 = [];
                folders_path = [];
                for I = 1:size(obj.classes,2)
                    dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,obj.classes(I))));
                    files_num = zeros(size(dir_table,1)-2,1);
                    for J = 3:size(dir_table,1)
                        files_num(J-2) = size(struct2table(dir(fullfile(dir_table.folder{J},dir_table.name{J},"x40","**",obj.classes(I),"*.jpg"))),1);
                    end
                    files_num_on_each_class_x20 = [files_num_on_each_class_x20;files_num];
                    folders_path = [folders_path;dir_table.folder(3:end) + "\" + dir_table.name(3:end)];
                end
                writetable(table(folders_path,files_num_on_each_class_x20,VariableNames=["PATH","NUM"]),fullfile(obj.document_path,"x40_number_of_files.csv"));
            end
            obj.cropping_area_save;
        end
        function cropping_area_show(obj,file_path)
            split_file_path = strsplit(file_path,filesep);
            file_name = split_file_path(end);
            size_folder_name = num2str(obj.height)+"_" + num2str(obj.width);
            augmented_file_name = strrep(file_name,".jpg","");
            dir_table = struct2table(dir(fullfile(split_file_path{1:end-1},size_folder_name,"**",strcat(augmented_file_name,"*.jpg"))));
            im = imread(file_path);
            label = zeros(size(im,1),size(im,2));
            for I =1:size(dir_table,1)
                idx = strsplit(strrep(strrep(dir_table.name{I},augmented_file_name,""),".jpg",""),"_");
                row_idx = str2num(idx(2));
                col_idx = str2num(idx(3));
                label((row_idx-1)*obj.height+1:row_idx*obj.height,(col_idx-1)*obj.width+1:col_idx*obj.width)=1;
            end
            imwrite(labeloverlay(im,label),strcat(strrep(file_path,file_name,""),strcat("labeloverlay_",file_name)));
        end
        function cropping_area_save(obj)
            dir_table = struct2table(dir(fullfile(obj.ndpi_files_path,"**","x*","SmallSize*.jpg")));
            for I =1:size(dir_table,1)
                obj.cropping_area_show(fullfile(dir_table.folder{I},dir_table.name{I}));
            end
        end
        function recropping(obj,height,width,resolution)
            cropping_folder_name = strcat(num2str(height),"_",num2str(width));
            if resolution == "x20" || resolution == "x40"
                for K = 1:size(obj.file_properties,1)

                    folder_tree = strsplit(obj.file_properties.files{K},filesep);
                    class_name = folder_tree{end-2};
                    dir_folder_path = fullfile(folder_tree{1:end-1});
                    if not(exist(fullfile(dir_folder_path,resolution,cropping_folder_name,class_name),"dir"))
                        mkdir(fullfile(dir_folder_path,resolution),cropping_folder_name);
                        mkdir(fullfile(dir_folder_path,resolution,cropping_folder_name),class_name);
                    end
                    if exist(fullfile(dir_folder_path,strcat("_",folder_tree{end-1},"_",resolution,"_","label.zip")))
                        unzip(fullfile(dir_folder_path,strcat("_",folder_tree{end-1},"_",resolution,"_","label.zip")),fullfile(dir_folder_path,resolution));

                        size_folder_name = cropping_folder_name;
                        dir_table = struct2table(dir(fullfile(dir_folder_path,resolution,"*SmallSize*_x*_*.jpg")));
                        dir_table = dir_table(cellfun(@(file) not(contains(string(file),"labeloverlay")),dir_table.name),:);
                        if size(dir_table,1)>1
                            for idx=1:size(dir_table,1)
                                im =imread(fullfile(dir_table.folder{idx},dir_table.name{idx}));
                                if contains(dir_table.name{idx},"norm3")
                                    label = readmatrix(fullfile(dir_table.folder{idx},strrep(strrep(dir_table.name{idx},".jpg",".csv"),"norm3_","")));
                                else
                                    label = readmatrix(fullfile(dir_table.folder{idx},strrep(dir_table.name{idx},".jpg",".csv")));
                                end
                                label = makeImageRough(label,5,0.1);
                                outer_index = 10;
                                white_in_tissue = 20;
                                obj.width = width;
                                obj.height = height;
                                ncol = fix(size(im,2)/obj.width);
                                nrow = fix(size(im,1)/obj.height);
                                for I=1:nrow
                                    for J=1:ncol
                                        L = label((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width);
                                        p = sum(L==outer_index,"all")/obj.width/obj.height;
                                        p_white_in_tissue = sum(L==white_in_tissue,"all")/obj.width/obj.height;
                                        if p==0 && p_white_in_tissue<0.999
                                            im2 = im((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width,:);
                                            imwrite(im2,fullfile(dir_table.folder{idx},size_folder_name,class_name,strcat(strrep(dir_table.name{idx},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")))

                                        end
                                    end
                                end
                            end
                        end
                    elseif size(dir_table,1)==1
                        im =imread(fullfile(dir_table.folder,dir_table.name));
                        if contains(dir_table.name,"norm3")
                            label = readmatrix(fullfile(dir_table.folder,strrep(strrep(dir_table.name,".jpg",".csv"),"norm3_","")));
                        else
                            label = readmatrix(fullfile(dir_table.folder,strrep(dir_table.name,".jpg",".csv")));
                        end
                        label = makeImageRough(label,5,0.1);
                        outer_index = 10;
                        white_in_tissue = 20;
                        ncol = fix(size(im,2)/obj.width);
                        nrow = fix(size(im,1)/obj.height);
                        for I=1:nrow
                            for J=1:ncol
                                L = label((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width);
                                p = sum(L==outer_index,"all")/obj.width/obj.height;
                                p_white_in_tissue = sum(L==white_in_tissue,"all")/obj.width/obj.height;
                                if p==0 && p_white_in_tissue<0.999
                                    im2 = im((I-1)*obj.height+1:(I-1)*obj.height+obj.height,(J-1)*obj.width+1:(J-1)*obj.width+obj.width,:);
                                    imwrite(im2,fullfile(dir_table.folder{idx},size_folder_name,class_name,strcat(strrep(dir_table.name{idx},".jpg",""),"_",num2str(I),"_",num2str(J),".jpg")))

                                end
                            end
                        end
                    end
                    % for I = 1:size(obj.file_properties,1)
                    %     if string(obj.file_properties.files{I}) == string(file_path)
                    %         properties = obj.file_properties;
                    %         properties.Cropping(I) = true;
                    %     end
                    % end
                    % obj.file_properties = properties;

                    delete(fullfile(dir_folder_path,resolution,"*.csv"));
                end
            end
        end
    end
end
function new_label = makeImageRough(label,interval,ratio)
label = uint8(not(label == 20)).*uint8(not(label == 10));
width = round((interval-1)/2);
new_label = zeros(size(label));
for I = width+1:interval:size(label,1)-width
    for J = width+1:interval:size(label,2)-width
        if sum(label(I-width:I+width,J-width:J+width),"all")>=(2*width+1)*(2*width+1)*ratio
            new_label(I-width:I+width,J-width:J+width)=1;
        else
            new_label(I-width:I+width,J-width:J+width)=0;
        end
    end
end

BW = new_label;%tissue is equal to 1
BW2 = (imfill(BW,"hole"));%outer region is equal to 0
BW = uint8(abs(BW-BW2));%white region in tissue is eqaul to 1
new_label = uint8(new_label);
new_label = new_label.*(uint8(not((BW))))+(uint8(BW))*20;%white region index in tissue = 20
new_label = new_label.*(uint8(BW2))+(uint8(not((BW2))))*10;%outer region index in tissue = 10

end