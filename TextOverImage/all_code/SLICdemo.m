%======================================================================
%SLIC demo
% Copyright (C) 2015 Ecole Polytechnique Federale de Lausanne
% File created by Radhakrishna Achanta
% Please also read the copyright notice in the file slicmex.c 
%======================================================================
%Input parameters are:
%[1] 8 bit images (color or grayscale)
%[2] Number of required superpixels (optional, default is 200)
%[3] Compactness factor (optional, default is 10)
%
%Ouputs are:
%[1] labels (in raster scan order)
%[2] number of labels in the image (same as the number of returned
%superpixels
%
%NOTES:
%[1] number of returned superpixels may be different from the input
%number of superpixels.
%[2] you must compile the C file using mex slicme.c before using the code
%below
%======================================================================
                                    
function labels = SLICdemo(img)
%% resize_factor = 256;
%% img = imread(img);
%% img = imresize(img, resize_factor/size(img, 2));
                                    
[labels, numlabels] = slicmex(img, 400, 10);  %numlabels is the same as number of superpixels
                                    
labels = labels + 1;  %% add +1 to all elements
                                    
[nrLines nrColumns] = size(labels);
                                    
%% for i = 2 : (nrLines - 1)
%%     for j = 2 : (nrColumns - 1)
%%        if labels(i, j) != labels(i-1, j) || labels(i, j) != labels(i, j-1) || labels(i, j) != labels(i+1, j) || labels(i, j) != labels(i, j+1)
%%             img(i, j, :) = 0;
%%        end
%%     end
%% end
                                
%% imshow(img);

