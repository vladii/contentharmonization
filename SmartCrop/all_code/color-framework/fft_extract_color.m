function fft_extract_color(image_path, text, font, font_size, X, Y)
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

    %% Create a low-pass filter.
    CUTOFF = 10;
    ORDER = 1;

    MIDDLE_L = text_image_height / 2;
    MIDDLE_C = text_image_width / 2;

    filter = [];
    for x = 1 : text_image_height
        for y = 1 : text_image_width
            %% Butterworth filter.
            %% filter(x, y) = 1 / (1 + (((x - MIDDLE_L)^2 + (y - MIDDLE_C)^2) / CUTOFF)^(2*ORDER));

            %% Gaussian filter.
            d = sqrt( (x - MIDDLE_L)^2 + (y - MIDDLE_C)^2 );
            filter(x, y) = exp( -( (d^2) / (2*(CUTOFF^2)) ) );

            %% Normal filter.
            %% if abs(x - MIDDLE_L) <= CUTOFF && abs(y - MIDDLE_C) <= CUTOFF
            %%     filter(x, y) = 1.0;
            %% else
            %%     filter(x, y) = 0.0;
            %% end
        end
    end

    %% Solve for H (Hue).
    HMatrix = [];
    for x = X : rightX
        for y = Y : rightY
            HMatrix(x - X + 1, y - Y + 1) = original_image(x, y, 1);
        end
    end

    FFTHMatrix = fft2(HMatrix);
    FFTHMatrix = fftshift(FFTHMatrix);
    FilteredHMatrix = real(FFTHMatrix) .* filter + (imag(FFTHMatrix) .* filter) * i;

    FilteredHMatrix = ifftshift(FilteredHMatrix);
    HMatrix = ifft2(FilteredHMatrix);

    %% Solve for S (Saturation).
    SMatrix = [];
    for x = X : rightX
        for y = Y : rightY
            SMatrix(x - X + 1, y - Y + 1) = original_image(x, y, 2);
        end
    end

    FFTSMatrix = fft2(SMatrix);
    FFTSMatrix = fftshift(FFTSMatrix);
    FilteredSMatrix = real(FFTSMatrix) .* filter + (imag(FFTSMatrix) .* filter) * i;

    FilteredSMatrix = ifftshift(FilteredSMatrix);
    SMatrix = ifft2(FilteredSMatrix);

    %% Solve for B (Brightness).
    BMatrix = [];
    for x = X : rightX
        for y = Y : rightY
            BMatrix(x - X + 1, y - Y + 1) = original_image(x, y, 3);
        end
    end

    FFTBMatrix = fft2(BMatrix);
    FFTBMatrix = fftshift(FFTBMatrix);
    FilteredBMatrix = real(FFTBMatrix) .* filter + (imag(FFTBMatrix) .* filter) * i;

    FilteredBMatrix = ifftshift(FilteredBMatrix);
    BMatrix = ifft2(FilteredBMatrix);

    %% figure;
    %% plot(real(FFTBMatrix));

    %% Normalize all matrices to [0, 1].
    HMatrix = real(HMatrix);
    SMatrix = real(SMatrix);
    BMatrix = real(BMatrix);

    HMatrix = (HMatrix - min(HMatrix(:))) ./ (max(HMatrix(:)) - min(HMatrix(:)));
    SMatrix = (SMatrix - min(SMatrix(:))) ./ (max(SMatrix(:)) - min(SMatrix(:)));
    BMatrix = (BMatrix - min(BMatrix(:))) ./ (max(BMatrix(:)) - min(BMatrix(:)));

    %% Show progress.
    result_matrix = [];
    averageH = 0.0;
    averageS = 0.0;
    averageB = 0.0;

    for x = 1 : text_image_height
        for y = 1 : text_image_width
            result_matrix(x, y, 1) = real(HMatrix(x, y));
            result_matrix(x, y, 2) = real(SMatrix(x, y));
            result_matrix(x, y, 3) = real(BMatrix(x, y));

            averageH = averageH + result_matrix(x, y, 1);
            averageS = averageS + result_matrix(x, y, 2);
            averageB = averageB + result_matrix(x, y, 3);
        end
    end

    averageH /= text_image_height * text_image_width;
    averageS /= text_image_height * text_image_width;
    averageB /= text_image_height * text_image_width;

    solH = averageH;
    solS = averageS;
    solB = averageB;

    solH
    solS
    solB

    initialAverageB = 0.0;
    for x = X : rightX
        for y = Y : rightY
            initialAverageB += original_image(x, y, 3);
            original_image(x, y, :) = result_matrix(x - X + 1, y - Y + 1, :);

            if (text_image(x - X + 1, y - Y + 1) == 0)
                original_image(x, y, 1) = solH;
                original_image(x, y, 2) = solS;
                original_image(x, y, 3) = solB;
            end
        end
    end

    initialAverageB /= text_image_height * text_image_width;
    initialAverageB

    original_image = hsv2rgb(original_image);

    outname = ['try_' image_path];
    imwrite(original_image, outname);
end