%% readl all images and masks
close all, clear, clc
%read all images
all_img = cell(21, 1);

for id = 1:size(all_img,1)
    if id<= 9
        img = imread(['image00' num2str(id) '.tif']);
        all_img{id} = img;
    else 
        img = imread(['image0' num2str(id) '.tif']);
        all_img{id} = img;
    end
end
specular_mask=imread('ZhuoerLyu-lyu.254/Assignment_1_tif_images/Pear/mask_dir_1.png');
specular_mask=double(rgb2gray(specular_mask));
lambertian_mask=imread('ZhuoerLyu-lyu.254/Assignment_1_tif_images/Pear/mask_I.png');
lambertian_mask=double(rgb2gray(lambertian_mask));
apple_mask=imread('ZhuoerLyu-lyu.254/Assignment_1_tif_images/Pear/pearmask.png');
apple_mask=double(rgb2gray(apple_mask));



%% calibration light
%find the centroid and radius
[i,j]=find(specular_mask==255);
x_max=max(i);
x_min=min(i);
y_max=max(j);
y_min=min(j);
x_center=(x_max+x_min)/2;
y_center=(y_max+y_min)/2;
radius=(x_max-x_min)/2;
%record light direction and light intensity
light_dir=[];
light_inten=[];
for id = 1:size(all_img, 1)
    img=rgb2gray(all_img{id});
    sp=(img.*specular_mask)/255;
    [x1,y1]=find(sp==max(max(sp)));
    x=mean(x1);
    y=mean(y1);
    nx=(x-x_center)/radius;
    ny=(y-y_center)/radius;
    nz=sqrt(1-nx.^2-ny.^2);
    N=[nx,ny,nz];
    R=[0,0,1];
    ld=2*(N*R')*N-R;
    light_dir=[light_dir;ld];

    la=(img.*lambertian_mask)/255;
    [x2,y2]=find(la==max(max(la)));
    inten=la(x2,y2);
    light_inten=[light_inten;inten];
end
% print('the light direction of all images are:',light_dir)
% print('the light intensity of all images are:',light_inten)
%% normal map and albedo map

num_img = size(all_img, 1);

img = all_img{1};
[row, col, ~] = size(img);

T = zeros(row, col, num_img);

for id = 1:num_img
    im = rgb2gray(all_img{id});
    for h = 1:row
        for w = 1:col
            if apple_mask(h, w)
                inten=double(im(h,w));
                T(h, w, id) = 20*inten;
            end
        end
    end
end

normal_matrix = zeros(row, col, 3);
albedo=zeros(row, col);

for h = 1:row
    for w = 1:col
        if apple_mask(h, w)
            i = reshape(T(h, w, :), [num_img, 1]);
            %normalize to get rid of shading part
            g = (light_dir.'*light_dir)\(light_dir.'*i);
            albedo(h,w) = norm(g);
            if norm(g) ~= 0
                n = g/norm(g);
            else
                n = [0; 0; 0];
            end
            normal_matrix(h, w, :) = n;
            
        end
    end
end

%imwrite(N, sprintf('apple_normal_matrix1.png'));
normal_matrix_for_show = (normal_matrix+1)/2;

figure
imshow(normal_matrix_for_show)
title('Normals')

figure
imshow(albedo)
title('Albedo')

figure 
imshow(normal_matrix(:,:,3).*albedo)
title('rerendered image with the same direction of light and viewing ')

%% using method 2 to recover matrix



%building linear equation system
b = zeros(row*col*2,1);
% count the position for each row
count_in_coordinate = 1
count_in_row = 1;
count_in_col = 1;
x_coordinate = zeros(row*col*4,1);
y_coordinate = zeros(row*col*4,1);
value = zeros(row*col*4,1);

for x = 1:row
    for y = 1:col
        if x<row && y<col
            x_coordinate(count_in_coordinate:count_in_coordinate+3) = [count_in_row,count_in_row,count_in_row+1,count_in_row+1];
            y_coordinate(count_in_coordinate:count_in_coordinate+3) = [count_in_col,count_in_col+1,count_in_col,count_in_col+col];
            value(count_in_coordinate:count_in_coordinate+3) = [1, -1, 1, -1];
            count_in_coordinate = count_in_coordinate+4;
            b(count_in_row,1) = normal_matrix(x,y,2)/normal_matrix(x,y,3);
            b(count_in_row+1,1) = normal_matrix(x,y,1)/normal_matrix(x,y,3);
        elseif x == row && y<col %when pixel is at the last rows;
            x_coordinate(count_in_coordinate:count_in_coordinate+2) = [count_in_row,count_in_row,count_in_row+1];
            y_coordinate(count_in_coordinate:count_in_coordinate+2) = [count_in_col,count_in_col+1,count_in_col];
            value(count_in_coordinate:count_in_coordinate+2) = [1, -1, 1];
            count_in_coordinate = count_in_coordinate+3;
            b(count_in_row,1) = normal_matrix(x,y,2)/normal_matrix(x,y,3);
            b(count_in_row+1,1) = normal_matrix(x,y,1)/normal_matrix(x,y,3);
        
        elseif x<row && y==col %when pixel is at the last cols
            x_coordinate(count_in_coordinate:count_in_coordinate+2) = [count_in_row,count_in_row+1,count_in_row+1];
            y_coordinate(count_in_coordinate:count_in_coordinate+2) = [count_in_col,count_in_col,count_in_col+col];
            value(count_in_coordinate:count_in_coordinate+2) = [1, 1, -1];
            count_in_coordinate = count_in_coordinate+3;
            b(count_in_row,1) = normal_matrix(x,y,2)/normal_matrix(x,y,3);
            b(count_in_row+1,1) = normal_matrix(x,y,1)/normal_matrix(x,y,3);
       
        else x==row && y== col %when pixel is at the last position
            x_coordinate(count_in_coordinate:count_in_coordinate+1) = [count_in_row,count_in_row+1];
            y_coordinate(count_in_coordinate:count_in_coordinate+1) = [count_in_col,count_in_col];
            value(count_in_coordinate:count_in_coordinate+1) = [1, 1];
            count_in_coordinate = count_in_coordinate+2;
            b(count_in_row,1) = normal_matrix(x,y,2)/normal_matrix(x,y,3);
            b(count_in_row+1,1) = normal_matrix(x,y,1)/normal_matrix(x,y,3);
        end
        count_in_row = count_in_row + 2;
        count_in_col = count_in_col + 1;
    end
end
b(isnan(b)) = 0;

x_coordinate = nonzeros(x_coordinate)';
y_coordinate = nonzeros(y_coordinate)';
value = nonzeros(value)';

coe = sparse(x_coordinate,y_coordinate,value);
height = lsqminnorm(coe,b);

height_matrix = reshape(height,[col,row])';
height_matrix_for_show = (height_matrix-min(min(height_matrix)));

figure;
axis equal;
mesh(height_matrix_for_show.*apple_mask);
title('recovered 3D surface')
colormap gray;
view(158,80)

figure;
imshow(height_matrix_for_show/max(max(height_matrix_for_show)));
title('height map')