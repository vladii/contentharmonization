# Description
Text Over Image - it places text over an image, choosing the correct position and color (more or less :-D). This tool is basically written in Octave and has some parts which use Javascript. Author: Vlad Ionescu, vladn.ionescu@gmail.com.

# How it works
It uses some algorithms, like:
- computer vision algorithms (finding interest points)
- geometry algorithms (convex hull, bresenham etc.)
- numerical algorithms (FFT, KMeans etc.)
- machine learning algorithms (for finding the colors etc.)

The explanation of used algorithms and methods are too complex to be described here, but some documentation exists and was provided by me, where I explained everything. Just ask for it.

# Prerequisites
You should install the following software and libraries before trying to run it:
- Octave
- Octave packages: image (and all its dependencies). Install it via forge (pkg install package_name.version)
- harfbuzz
- nodejs
- npm
- convnetjs nodejs library (npm install convnetjs)
- express, gm, multer, serve-index, serve-static nodejs libraries

# How to run it
The main code is presented in ./all_code/spectral_residual.m. This is the entrypoint. But there exists a server which exposes all the implemented features, run it by entering in ./imageserver directory and typing:
node server.js
Now open your browser and enter: localhost:6969 and you'll find an interface for placing the text. Check server.js script to see how to manually call spectral_residual.m functions.

Note: for using the Google Prediction API, you should insert in ./all_code/color-framework/script-3-3D-google.js your Google developer API key and to generate a certificat (googlekey.pem) which will be stored in ./all_code/color-framework folder.

# It will produce the following images:
1. imagename_scaled -> the image scaled at lower dimensions
2. imagename_saliency -> the saliency map using the algorithm with FFT
3. imagename_stage1 & imagename_stage2 -> the saliency maps using the algorithm with Graphs
4. imagename_old_interest -> the interest points obtained by the algorithm with FFT
5. imagename_manifold_ranking_interest -> the interest points obtained by the algorithm wiht Graphs
6. imagename_new_interest -> the interest points obtained by the combination of previous algorithms
7. imagename_many_polygons -> the image with polygons which cover every cluster of points
8. imagename_united_polygons -> the image where the previous polygons where united in some bigger ones
9. imagename_dropped_polygons -> the image there all smaller polygons are dropped
10. imagename_remained_interest_points -> the image with the remained interest points (points inside polygons)
11. imagename_remained_interest_points_original_dim -> previous image scaled to initial dimensions
12. dominant_imagename -> three dominant colors from the zone where the text will be placed
13. dominant_one_imagename -> one dominant color from the zone where the text will be placed
14. complement_imagename -> the complementary color of the previous image (using some mathematics rules)
15. other irelevant images
16. text_imagename -> the final image with the text placed over it.

# Improvements
There are some things which can be improved:
- the quality of the Octave code. Octave is very poor on performing nested loops (even for iterating on a 2000x2000 matrix), but it's good on vectorial instructions. There are unoptimized portions of code which should be replaced with such instructions.
- the machine learning algorithm (and the training data set). In this folder should be two versions: one which uses ConvnetJs (a library for machine learning written in Javascript) and one which makes calls to Google Prediction API. None of them works perfectly (and also, they produce only black and white colors - but this can be easily changed).
- if there are some multiple free zones, choose smart over which one to place the text. Currently, it's random.

# Known limitations
- Text should NOT contain spaces (harf-buzz).
- If text if too big and no free zone (without interest points in it) is found, then it doesn't place any text.
- Who knows what other things? :-(
