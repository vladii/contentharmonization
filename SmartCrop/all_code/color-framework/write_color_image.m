function write_color_image(image_path, text, font, font_size, X, Y, H, S, B)
    font_size = str2num(font_size);
    X = str2num(X);
    Y = str2num(Y);
    H = str2num(H);
    S = str2num(S);
    B = str2num(B);

    %% Run command to generate the image with rendered text. Use harf-buzz.
    command = ["hb-view --output-file=WrittenTextTmp.png --output-format=png --margin=10 --font-size=" int2str(font_size) " " font " " text];
    system(command);

    %% Read images and construct the pixel matrix.
    original_image = rgb2hsv(imread(image_path));
    text_image = imread("WrittenTextTmp.png");

    text_image_width = size(text_image, 2);
    text_image_height = size(text_image, 1);

    rightX = X + text_image_height - 1;
    rightY = Y + text_image_width - 1;

    %% Put text and output the image.
    for x = X : rightX
        for y = Y : rightY
            if (text_image(x - X + 1, y - Y + 1) == 0)
                original_image(x, y, 1) = H;
                original_image(x, y, 2) = S;
                original_image(x, y, 3) = B;
            end
        end
    end

    original_image = hsv2rgb(original_image);

    outname = ['text_' image_path];
    imwrite(original_image, outname);
end
