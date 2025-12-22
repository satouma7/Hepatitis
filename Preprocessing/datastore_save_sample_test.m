clear;

ds = datastore("all_three_colum_rgb.csv");

im = imread("1_x20_z0_i1j2.jpg");
ncol = size(im,2);
nrow = size(im,1);
sum_row = uint64(nrow*ncol);

t = table('VariableTypes',{'uint8','uint8','uint8'},'Size',[sum_row,3]);


ds.ReadSize=500000;
next_line = 1;

while next_line < sum_row - ds.ReadSize

    table_from_ds = read(ds);


    if size(table_from_ds) == size(t(next_line:next_line+ds.ReadSize-1,:))
        t(next_line:next_line+ds.ReadSize-1,:) = table_from_ds;
        next_line=next_line+ds.ReadSize;
    else
        t(next_line:next_line+size(table_from_ds,1)-1,:) = table_from_ds;
        next_line=next_line+size(table_from_ds,1);
    end

end
