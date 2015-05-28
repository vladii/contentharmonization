---------- HOW TO RUN THIS CODE ----------

1) Install all required dependencies:
a) Octave:
brew install octave

b) Octave packages:
pkg install -forge image
* also install all needed dependencies

c) Harf-buzz (Font rendering):
brew install harfbuzz

d) Node.js:
brew install nodejs

e) ConvNet.js Neural Network (Node.js module):
npm install convnetjs

2) Run code:
node script-3-3D.js image_path=\"XXX.bmp\" text=\"VladIonescu\" font=\"OpenSans-Regular.ttf\" font_size=50 pos_x=250 pos_y=250

---------- OUTPUT ----------
It will produce several files:
a) WrittenTextTmp.png
Rendered (by hb-view) text given as argument.

b) cropped_XXX.bmp 
Rectangle cropped from the original image, where the text will be placed.

c) dominant_XXX.bmp
Three dominant colors from that rectangle.

d) dominant_one_XXX.bmp
An attempt to summarize those three dominant colors to a single one.

e) complement_XXX.bmp
An attempt to obtain the complementary color of the dominant one. It uses some formulas
applied on HSB wheel, but it doesn't work very well.

f) text_XXX.bmp
This is mostly what you are interested in. This is the final image, with the text placed
in the given position, with a contrasted color.
