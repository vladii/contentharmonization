
clear all;

max_recursion_depth(100000);

function img = bresenhamLine(img, startPoint, endPoint, color)
    %Check for vertical line, x0 == x1
    if( startPoint(1) == endPoint(1) )
        %Draw vertical line
        for i = (startPoint(2):endPoint(2))
            img(startPoint(1), i, 1) = color(1);
            img(startPoint(1), i, 2) = color(2);
            img(startPoint(1), i, 3) = color(3);
        end
    end

    %Simplified Bresenham algorithm
    dx = abs(endPoint(1) - startPoint(1));
    dy = abs(endPoint(2) - startPoint(2));

    if(startPoint(1) < endPoint(1))
        sx = 1;
    else
        sx = -1;
    end

    if(startPoint(2) < endPoint(2))
        sy = 1;
    else
        sy = -1;
    end

    err = dx - dy;
    pixel = startPoint;

    while(true)
        img(pixel(1), pixel(2), 1) = color(1);
        img(pixel(1), pixel(2), 2) = color(2);
        img(pixel(1), pixel(2), 3) = color(3);

        if( pixel == endPoint )
            break;
        end

        e2 = 2*err;

        if( e2 > -dy )
            err = err - dy;
            pixel(1) = pixel(1) + sx;
        end

        if( e2 < dx )
            err = err + dx;
            pixel(2) = pixel(2) + sy;
        end
    end
end

addpath('.');

saldir = "./saliencymap/";
imgRoot = "./test/";

imnames = dir([imgRoot 'Image_13.bmp']);

global resize_factor = 256;

average_matrix = zeros(resize_factor, resize_factor);

known_average_matrix = dlmread('amplitude-average-matrix.txt');

%% ------------------------- Convex Hull ------------------------ %%

function ok = collinear(x, y)
    slopes = [];
    ok = true;

    for i = 2 : size(x, 1);
        if x(i) == x(1)
            slopes(i - 1) = +99999999;
        else
            slopes(i - 1) = (y(i) - y(1)) / (x(i) - x(1));
        end
    end

    slopes = sort(slopes);
    for i = 2 : size(slopes, 2)
        if slopes(i) != slopes(1)
            ok = false;
            break;
        end
    end
end

function H = convhull_wrapper(x_coord, y_coord)
    if size(x_coord, 1) == 1
        H = [1];
    elseif size(x_coord, 1) == 2
        H = [1; 2];
    else
        %% Check if all points are collinear (because convhull fails in this case)
        areCollinear = collinear(x_coord, y_coord);

        if areCollinear
            %% Return the left-most point and the right-most one.
            indMin = 0;
            indMax = 0;

            for i = 1 : size(x_coord, 1)
                if indMin == 0 || x_coord(i) < x_coord(indMin) || (x_coord(i) == x_coord(indMin) && y_coord(i) < y_coord(indMin))
                    indMin = i;
                end

                if indMax == 0 || x_coord(i) > x_coord(indMax) || (x_coord(i) == x_coord(indMax) && y_coord(i) > y_coord(indMax))
                    indMax = i;
                end
            end

            H = [indMin; indMax];

        else
            H = convhull(x_coord, y_coord);
        end
    end
end


%% ------------------------- BFS on matrix CODE ----------------- %%

global newLinePolygonImgGlobal = [];
global polygonImgGlobal = [];
global dirx = [-1 1 0 0 -1 -1 1 1];
global diry = [0 0 -1 1 -1 1 -1 1];

function BFSonMatrix(x, y, depth)
    global newLinePolygonImgGlobal;
    global polygonImgGlobal;
    global dirx;
    global diry;
    global resize_factor;

    sz = size(newLinePolygonImgGlobal, 1);
    sz ++;
    newLinePolygonImgGlobal(sz, 1) = x;
    newLinePolygonImgGlobal(sz, 2) = y;

    polygonImgGlobal(x, y, 1) = -2;
    polygonImgGlobal(x, y, 2) = -2;
    polygonImgGlobal(x, y, 3) = -2;

    for i = 1 : 8
        newx = x + dirx(i);
        newy = y + diry(i);

        if newx > 0 && newy > 0 && newx <= resize_factor && newy <= resize_factor && ...
            polygonImgGlobal(newx, newy, 1) == -1 && polygonImgGlobal(newx, newy, 2) == -1 && polygonImgGlobal(newx, newy, 3) == -1
            BFSonMatrix(newx, newy, depth + 1);
        end
    end
end

%% ------------------------- MAIN CODE ------------------------- %%

for ii=1:length(imnames)
    imname = [imgRoot imnames(ii).name];
    %% Read image from file
    inImg = im2double(rgb2gray(imread(imname)));
    %% inImg = imresize(inImg, resize_factor/size(inImg, 2));
    inImg = imresize(inImg, [resize_factor resize_factor]);

    originalImage = imread(imname);
    originalImage = imresize(originalImage, [resize_factor resize_factor]);

    outname = [saldir imnames(ii).name(1:end-4) '_scaled' '.png'];
    imwrite(inImg, outname);

    %% ---------------------- Spectral Residual (FFT) Saliency Map -------------------- %%

    %% Spectral Residual
    myFFT = fft2(inImg); 
    myLogAmplitude = log(abs(myFFT));
    myPhase = angle(myFFT);

    %% instead of applying this filter, use previous known information
    mySpectralResidual = myLogAmplitude - imfilter(myLogAmplitude, fspecial('average', 3), 'replicate');
    %% mySpectralResidual = myLogAmplitude - known_average_matrix;

    %% compute saliency map
    saliencyMap = abs(ifft2(exp(mySpectralResidual + i*myPhase))).^2;

    %% compute element-by-element sum in order to find the average log-amplitude
    average_matrix = average_matrix + myLogAmplitude;

    %% After Effect
    saliencyMap = mat2gray(imfilter(saliencyMap, fspecial('gaussian', [10, 10], 2.5)));
    %% imshow(saliencyMap);

    %% write saliency map
    outname = [saldir imnames(ii).name(1:end-4) '_saliency' '.png'];
    imwrite(saliencyMap, outname);

    %% ----------------------------- Compute OLD Points of Interest --------------------- %%

    %% compute points of interest
    threshold = mean(mean(saliencyMap, 2)) * 2;
    index = 0;
    for pp = 1:size(saliencyMap, 1)
        for kk = 1:size(saliencyMap, 2)
            if saliencyMap(pp, kk) > threshold
                O(pp, kk) = 1;

                index ++;
                points(index, 1) = pp;
                points(index, 2) = kk;

                %% extra dimensions
                %% points(index, 3) = sqrt(originalImage(pp, kk, 1));
                %% points(index, 4) = sqrt(originalImage(pp, kk, 2));
                %% points(index, 5) = sqrt(originalImage(pp, kk, 3));
            else
                O(pp, kk) = inImg(pp, kk);
            end
        end
    end

    %% write points of interest
    outname = [saldir imnames(ii).name(1:end-4) '_old_interest' '.png'];
    imwrite(O, outname);

    %% --------------------- Saliency Map via Graph Based Manifold --------------------- %%

    graph_based_manifold_saliency_map = graph_based_manifold(imnames(ii).name);

    % Compute points of interes.
    threshold = mean(mean(graph_based_manifold_saliency_map, 2)) * 2;
    for pp = 1:size(graph_based_manifold_saliency_map, 1)
        for kk = 1:size(graph_based_manifold_saliency_map, 2)
            if graph_based_manifold_saliency_map(pp, kk) > threshold
                O(pp, kk) = 1;
            else
                O(pp, kk) = inImg(pp, kk);
            end
        end
    end

    %% write points of interest
    outname = [saldir imnames(ii).name(1:end-4) '_manifold_ranking_interest' '.png'];
    imwrite(O, outname);

    %% ----------------------------- Compute NEW Points of Interest --------------------- %%

    %% Combine these two methods (for better results?)
    %% Combine using sqrt(). (TODO: try another methods, too)
    for pp = 1:size(saliencyMap, 1)
        for kk = 1:size(saliencyMap, 2)
            saliencyMap(pp, kk) = saliencyMap(pp, kk) * sqrt(graph_based_manifold_saliency_map(pp, kk));
        end
    end

    %% compute points of interest
    threshold = mean(mean(saliencyMap, 2)) * 2;
    index = 0;
    points = [];
    for pp = 1:size(saliencyMap, 1)
         for kk = 1:size(saliencyMap, 2)
             if saliencyMap(pp, kk) > threshold
                O(pp, kk) = 1;

                index ++;
                points(index, 1) = pp;
                points(index, 2) = kk;
             else
                 O(pp, kk) = inImg(pp, kk);
             end
         end
    end

    %% write image with points of interest
    outname = [saldir imnames(ii).name(1:end-4) '_new_interest' '.png'];
    imwrite(O, outname);

    %% ------------------------ Write Points of Interest in a text file -------------------------- %%
    outname = [saldir imnames(ii).name(1:end-4) '_points' '.txt'];
    save(outname, 'points', '-ascii');

    %% ----------------------------------- PHASE 2 ------------------------------------ %%
    %% Group all interest points in small clusters using K-Means. We want to construct polygons
    %% which represent all interesting objects in the image, but we have two problems:
    %% 1. Points of interest are usually disconnected. That means we can't run just a simple BFS
    %%    and find the main objects in the image.
    %% 2. If we use K-Means to group them, we don't know what value to set K, mainly because we
    %%    don't know the number of objects in the image. Also, K-Means doesn't always find the
    %%    best (visually) clustering.
    %% The solution presented here does the following steps:
    %% 1. Group points in sqrt(nr_points) clusters, using K-Means.
    %% 2. Run convex hull algorithm on each cluster (because this small clusters also can be disconnected)
    %% 3. If two polygons will intersect each other, then we merge them in one bigger polygon.

    tic;

    NR_CLUSTERS = sqrt(size(points, 1));
    [idx, centers] = kmeans(points, NR_CLUSTERS, 20);   %% 20 iterations
    kmeans_time = toc;


    colors = [];
    for pp = 1 : NR_CLUSTERS
        colors(pp, :) = randi([0 255], 1, 3);
    end

    newImg = imread(imname);
    newImg = imresize(newImg, [resize_factor resize_factor]);

    polygonImg = int32(newImg);     %% Matrix with polygons
    polygonFinalImg = newImg;
    droppedPolygonsImg = newImg;

    for pp = 1 : size(points, 1)
        newImg(points(pp, 1), points(pp, 2), :) = colors(idx(pp), :);
    end

    for pp = 1 : NR_CLUSTERS
        points_cluster = [];
        idx_cluster = 0;

        for qq = 1 : size(idx)
            if idx(qq) == pp
                idx_cluster ++;
                points_cluster(idx_cluster, :) = points(qq, :);
            end
        end

        H = convhull_wrapper(points_cluster(:, 1), points_cluster(:, 2));

        for qq = 1 : size(H)
            next_point_index = qq + 1;
            if next_point_index > size(H)
                next_point_index = 1;
            end

            curr_point = points_cluster(H(qq), 1:2);
            next_point = points_cluster(H(next_point_index), 1:2);

            % rasterize line
            polygonImg = bresenhamLine(polygonImg, curr_point, next_point, [-1 -1 -1]);
            newImg = bresenhamLine(newImg, curr_point, next_point, [0 0 0]);
        end
    end

    %% write the image with NR_CLUSTERS convex polygons
    outname = [saldir imnames(ii).name(1:end-4) '_many_polygons' '.png'];
    imwrite(newImg, outname);

    %% try to connect smaller polygons in bigger ones
    %% do a BFS over the image (polygonImg) to find connected components of [-1 -1 -1]
    %% also, save each polygon in order to drop them later
    nrPolygons = 0;
    polygons = [];
    polygonImgGlobal = polygonImg;

    for pp = 1 : size(polygonImgGlobal, 1)
        for qq = 1 : size(polygonImgGlobal, 2)
            newLinePolygonImgGlobal = [];

            if polygonImgGlobal(pp, qq, 1) == -1 && polygonImgGlobal(pp, qq, 2) == -1 && polygonImgGlobal(pp, qq, 3) == -1
                BFSonMatrix(pp, qq, 0);

                %% do another convex hull on these points.
                Hnew = convhull_wrapper(newLinePolygonImgGlobal(:, 1), newLinePolygonImgGlobal(:, 2));

                nrPolygons ++;
                currPolygonIdx = 0;

                for ind = 1 : size(Hnew)
                    next_point_index = ind + 1;
                    if next_point_index > size(Hnew)
                        next_point_index = 1;
                    end

                    curr_point = newLinePolygonImgGlobal(Hnew(ind), 1:2);
                    next_point = newLinePolygonImgGlobal(Hnew(next_point_index), 1:2);

                    %% save points
                    polygons(nrPolygons, ind, :) = curr_point(:);

                    % rasterize line
                    polygonFinalImg = bresenhamLine(polygonFinalImg, curr_point, next_point, [0 0 0]);
                end

            end
        end
    end

    %% write the image with united polygons
    outname = [saldir imnames(ii).name(1:end-4) '_united_polygons' '.png'];
    imwrite(polygonFinalImg, outname);

    %% ----------------------------------- Drop Smaller Polygons ----------------------------------- %%
    %% The previous step produce a number of polygons (which represent the main objects in the image).
    %% But, because the non-determinist methods which I used, is possible that some polygons to be fake
    %% and we want to drop them. In this step, I'll drop all polygons which have an area smaller than
    %% THRESHOLD_AREA * area_of_the_biggest_polygon.

    THRESHOLD_AREA = 1 / 15;

    maxPolygonArea = 0;
    for pp = 1 : nrPolygons
        maxPolygonArea = max(maxPolygonArea, polyarea(polygons(pp, :, 1), polygons(pp, :, 2)));
    end

    final_after_drop_polygons = [];
    poly_idx = 0;
    for pp = 1 : nrPolygons
        if polyarea(polygons(pp, :, 1), polygons(pp, :, 2)) >= THRESHOLD_AREA * maxPolygonArea
            %% Keep this polygon. Draw it.
            poly_idx ++;
            final_after_drop_polygons(poly_idx, :, 1) = polygons(pp, :, 1);
            final_after_drop_polygons(poly_idx, :, 2) = polygons(pp, :, 2);

            for ind = 1 : size(polygons(pp, :, 1), 2)
                curr_point = polygons(pp, ind, 1:2);

                if ind + 1 > size(polygons(pp, :, 1), 2)
                    next_point = polygons(pp, 1, 1:2);
                else
                    next_point = polygons(pp, ind+1, 1:2);
                end

                if curr_point(1) == 0 && curr_point(2) == 0
                    break;
                end

                if next_point(1) == 0 && next_point(2) == 0
                    next_point = polygons(pp, 1, 1:2);
                end

                %% Of course, this step isn't very optimal, but I'm too lazy to make it better :-).
                droppedPolygonsImg = bresenhamLine(droppedPolygonsImg, curr_point, next_point, [0 0 0]);
            end
        end
    end

    %% Write the image with dropped polygons.
    outname = [saldir imnames(ii).name(1:end-4) '_dropped_polygons' '.png'];
    imwrite(droppedPolygonsImg, outname);


    %% ------------------------- Find the optimal zone where to place text ------------------------ %%
    %% We don't want to cover any interest point which are placed in the remained polygons.

    originalImage = imread(imname);

    ORIGINAL_HEIGHT = size(originalImage, 1);
    ORIGINAL_WIDTH = size(originalImage, 2);

    originalImage = imresize(originalImage, [resize_factor resize_factor]);

    interest_matrix = [];
    for x = 1 : size(originalImage, 1)
        for y = 1 : size(originalImage, 2)
            interest_matrix(x, y) = 0;
        end
    end

    %% Check if interest points are inside any of the remaining polygons.
    %% Here is implemented just a straight-forward bruteforce method. THIS CAN BE OPTIMIZED!
    for poly_idx = 1 : size(final_after_drop_polygons, 1)
        points_in_poly = inpolygon(points(:, 1), points(:, 2), final_after_drop_polygons(poly_idx, :, 1), final_after_drop_polygons(poly_idx, :, 2));

        for pp = 1 : size(points, 1)
            if points_in_poly(pp)
                interest_matrix(points(pp, 1), points(pp, 2)) = 1;
            end
        end
    end

    %% Write this matrix into an image file.
    outname = [saldir imnames(ii).name(1:end-4) '_remained_interest_points' '.png'];
    imwrite(interest_matrix, outname);

    %% Scale this interest matrix to original image size.
    big_interest_matrix = imresize(interest_matrix, [ORIGINAL_HEIGHT ORIGINAL_WIDTH]);

    originalImage = imread(imname);
    for x = 1 : size(originalImage, 1)
        for y = 1 : size(originalImage, 2)
            if big_interest_matrix(x, y) > 0
                originalImage(x, y, :) = [1 1 1];
            end
        end
    end

    outname = [saldir imnames(ii).name(1:end-4) '_remained_interest_points_original_dim' '.png'];
    imwrite(originalImage, outname);

    %% OOOOOOOOK! Now, let's run a simple algorithm.
    %% The problem we want to solve is: given a rectangle, find in O(1) if there is any
    %% interest point inside that rectangle. We have to do a preprocessing.

    %% Find the number of points in the left (same row) for a given cell.
    nrPointsLeft = [];
    for x = 1 : size(big_interest_matrix, 1)
        for y = 1 : size(big_interest_matrix, 2)
            nrPointsLeft(x, y) = 0;
            if y > 1
                nrPointsLeft(x, y) = nrPointsLeft(x, y - 1);
            end

            if big_interest_matrix(x, y) > 0
                nrPointsLeft(x, y) ++;
            end
        end
    end

    %% Find the number of points in the submatrix which starts in (1, 1) and ends in (x, y).
    nrPointsSubmatrix = [];
    for x = 1 : size(big_interest_matrix, 1)
        for y = 1 : size(big_interest_matrix, 2)
            nrPointsSubmatrix(x, y) = 0;
            if x > 1
                nrPointsSubmatrix(x, y) = nrPointsSubmatrix(x - 1, y);
            end

            nrPointsSubmatrix(x, y) += nrPointsLeft(x, y);
        end
    end

    %% We want to find a free position to place the text.
    font = "OpenSans-Regular.ttf";
    font_size = 50;
    text = "VladIonescu";

    %% Run command to generate the image with rendered text. Use harf-buzz.
    command = ["hb-view --output-file=WrittenTextTmp.png --output-format=png --margin=10 --font-size=" int2str(font_size) " " font " " text];
    system(command);

    %% We need only the size of the rendered text (the size of the rectangle).
    text_image = imread("WrittenTextTmp.png");

    text_image_width = size(text_image, 2);
    text_image_height = size(text_image, 1);

    %% Try random positions for the text until we find a free one.
    free_positions = [];
    free_positions_idx = 0;
    for x = 1 : ORIGINAL_HEIGHT - text_image_height
        for y = 1 : ORIGINAL_WIDTH - text_image_width
            x_down_text = x + text_image_height;
            y_down_text = y + text_image_width;

            %% Check if there is any interest point in this rectangle.
            nr_points_inside = nrPointsSubmatrix(x_down_text, y_down_text);

            if x > 1
                nr_points_inside -= nrPointsSubmatrix(x - 1, y_down_text);
            end

            if y > 1
                nr_points_inside -= nrPointsSubmatrix(x_down_text, y - 1);
            end

            if x > 1 && y > 1
                nr_points_inside += nrPointsSubmatrix(x - 1, y - 1);
            end

            if nr_points_inside == 0
                %% Free position.
                free_positions_idx ++;
                free_positions(free_positions_idx, 1) = x;
                free_positions(free_positions_idx, 2) = y;
            end
        end
    end

    rand('seed', time());
    rp = randi(free_positions_idx);
    xp = free_positions(rp, 1);
    yp = free_positions(rp, 2);

    disp([int2str(free_positions_idx) " free places!"]);

    %% We have a different script to place text and set its color. Just call it.
    command = ['node script-3-3D.js image_path=\"' imname '\" text=\"' text '\" font=\"' font '\" font_size=' int2str(font_size) ' pos_x=' int2str(xp) ' pos_y=' int2str(yp)];
    system(command);

end

nr_elements = length(imnames);
for pp=1:resize_factor
    for kk=1:resize_factor
        average_matrix(pp, kk) = average_matrix(pp, kk) / nr_elements;
    end
end

%% save('amplitude-average-matrix.txt', 'average_matrix', '-ascii');
