# Description
Smart Crop - crops the most interesting part of an image. Place a window with a given height/width over the zone with the most interesting points of the input image. This tool is basically written in Octave and has some parts which use Javascript. Author: Vlad Ionescu, vladn.ionescu@gmail.com.

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
- express, multer, serve-index, serve-static nodejs libraries

# How to run it
The main code is presented in ./all_code/spectral_residual.m. This is the entrypoint. But there exists a server which exposes all the implemented features, run it by entering in ./imageserver directory and typing:
node server.js
Now open your browser and enter: localhost:6969 and you'll find an interface for placing the text. Check server.js script to see how to manually call spectral_residual.m functions.

# Improvements
There are some things which can be improved:
- the quality of the Octave code. Octave is very poor on performing nested loops (even for iterating on a 2000x2000 matrix), but it's good on vectorial instructions. There are unoptimized portions of code which should be replaced with such instructions.
