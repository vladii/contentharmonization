function dominant_color(image_path, text, font, font_size, X, Y)
    font_size = str2num(font_size);
    X = str2num(X);
    Y = str2num(Y);

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

    rectangle = [];
    nrPoints = 0;
    for x = X : rightX
        for y = Y : rightY
            rectangle(x - X + 1, y - Y + 1, :) = original_image(x, y, :);
        end
    end

    SAMPLE_STEP = 5;

    block_matrix = [];
    nrPoints = 0;
    for x = X : SAMPLE_STEP : rightX
        for y = Y : SAMPLE_STEP : rightY
            nrPoints ++;
            block_matrix(nrPoints, 1) = original_image(x, y, 1);
            block_matrix(nrPoints, 2) = original_image(x, y, 2);
            block_matrix(nrPoints, 3) = original_image(x, y, 3);
        end
    end

    %% Run kmeans to find dominant colors
    NR_DOMINANT_COLORS = 3;

    [idx, centers] = kmeans(block_matrix, NR_DOMINANT_COLORS, 30);

    %% Compose result
    DIM = 200;
    show_colors = [];
    for x = 1 : DIM
        for y = 1 : (NR_DOMINANT_COLORS * DIM)
            id = floor(y / DIM);
            if mod(y, DIM) > 0
                id ++;
            end

            show_colors(x, y, 1) = centers(id, 1);
            show_colors(x, y, 2) = centers(id, 2);
            show_colors(x, y, 3) = centers(id, 3);
        end
    end

    %% Print all dominant colors
    for x = 1 : NR_DOMINANT_COLORS
        disp([num2str(centers(x, 1)) " " num2str(centers(x, 2)) " " num2str(centers(x, 3))]);
    end

    %% Show dominant colors of cropped zone.
    rectangle = hsv2rgb(rectangle);
    show_colors = hsv2rgb(show_colors);

    outname = ['dominant_' image_path];
    imwrite(show_colors, outname);

    outname = ['cropped_' image_path];
    imwrite(rectangle, outname);

    %% Compute a score for each dominant color.
    scores = [];
    for x = 1 : NR_DOMINANT_COLORS
        scores(x) = 0;
    end

    for x = 1 : size(idx)
        scores(idx(x)) ++;  %% Add +1 if this point belongs to this cluster.
    end

    %% Find complementary color of those NR_DOMINANT_COLORS.
    hue_saturation = [];
    lightness = [];

    for x = 1 : NR_DOMINANT_COLORS
        hue_saturation_lightness(x, 1) = 360 * centers(x, 1);   %% Circle angles
        hue_saturation_lightness(x, 2) = 100 * centers(x, 2);   %% Segment length
        hue_saturation_lightness(x, 3) = centers(x, 3);         %% Lightness
        hue_saturation_lightness(x, 4) = scores(x);             %% Score
    end

    %% Sort hue_saturation_lightness vector (by hue - the angle on color wheel)
    hue_saturation_lightness = sortrows(hue_saturation_lightness);

    final_vector = [hue_saturation_lightness(1, 1) hue_saturation_lightness(1, 2)];
    final_vector_score = hue_saturation_lightness(1, 4);

    for idx = 2 : NR_DOMINANT_COLORS
        angle_between = (hue_saturation_lightness(idx, 1) - final_vector(1));

        if angle_between < 180
            angle_right = angle_between * hue_saturation_lightness(idx, 4) / (hue_saturation_lightness(idx, 4) + final_vector_score);
            angle_left = angle_between - angle_right;

            big_area = final_vector(2) * hue_saturation_lightness(idx, 2) * sin(angle_between * pi / 180);
            solution = big_area / (final_vector(2) * sin(angle_right * pi / 180) + hue_saturation_lightness(idx, 2) * sin(angle_left * pi / 180));

            %% Compute score of the resulted vector.
            if hue_saturation_lightness(idx, 4) > final_vector_score
                final_vector_score = hue_saturation_lightness(idx, 4) - final_vector_score / (hue_saturation_lightness(idx, 4) + final_vector_score);
            else
                final_vector_score = final_vector_score - hue_saturation_lightness(idx, 4) / (hue_saturation_lightness(idx, 4) + final_vector_score);
            end

            final_vector(2) = solution;                         %% Result's segment length (Saturation)

        elseif angle_between > 180
            angle_between = angle_between - 180;
            angle_right = angle_between * final_vector_score / (hue_saturation_lightness(idx, 4) + final_vector_score);
            angle_left = angle_between - angle_right;

            big_area = final_vector(2) * hue_saturation_lightness(idx, 2) * sin(angle_between * pi / 180);
            solution = big_area / (hue_saturation_lightness(idx, 2) * sin(angle_right * pi / 180) + final_vector(2) * sin(angle_left * pi / 180));

            %% Compute score of the resulted vector.
            if hue_saturation_lightness(idx, 4) > final_vector_score
                final_vector_score = hue_saturation_lightness(idx, 4) - final_vector_score / (hue_saturation_lightness(idx, 4) + final_vector_score);
            else
                final_vector_score = final_vector_score - hue_saturation_lightness(idx, 4) / (hue_saturation_lightness(idx, 4) + final_vector_score);
            end

            final_vector(2) = solution;                         %% Result's segment length (Saturation)

        else
            %% angle_between is 180 degrees. Set the length of this segment to that one with the bigger score.
            if final_vector_score >= hue_saturation_lightness(idx, 4)
                final_vector(2) = final_vector(2);  %% Dont change the segment length
            else
                final_vector(2) = hue_saturation_lightness(idx, 2);
                final_vector_score = hue_saturation_lightness(idx, 4);
            end
        end

        final_vector(1) = final_vector(1) + angle_right;    %% Result's angle (Hue)
    end

    %% Find lightness.
    avg_lightness = 0.0;
    numitor = 0;
    for idx = 1 : NR_DOMINANT_COLORS
        numitor += hue_saturation_lightness(idx, 4);
        avg_lightness += hue_saturation_lightness(idx, 4) * hue_saturation_lightness(idx, 3);
    end

    avg_lightness /= numitor;

    %% Print dominant ONE color: [final_vector(1) final_vector(2) avg_lightness]
    %% disp("Dominant Color")
    %% [final_vector(1) final_vector(2) avg_lightness * 100]

    dom_color = [];
    for x = 1 : DIM
        for y = 1 : DIM
            dom_color(x, y, 1) = final_vector(1) / 360;
            dom_color(x, y, 2) = final_vector(2) / 100;
            dom_color(x, y, 3) = avg_lightness;
        end
    end

    dom_color = hsv2rgb(dom_color);

    outname = ['dominant_one_' image_path];
    imwrite(dom_color, outname);

    %% Find the complementary segment for final_vector on the circle
    final_vector(1) += 180;
    if final_vector(1) >= 360
        final_vector(1) -= 360;
    end

    final_vector(1) /= 360;

    %% Special rule for saturation.
    if final_vector(2) > 70
        final_vector(2) -= 30;
    else
        final_vector(2) += 30;
    end

    final_vector(2) /= 100;

    %% Also special rule for lightness.
    if avg_lightness > 0.5
        final_vector(3) = avg_lightness - 0.5;
    else
        final_vector(3) = avg_lightness + 0.5;
    end

    %% Print solution (dominant colors and complementary color).
    %% disp("Complementary color")
    %% [final_vector(1) * 360 final_vector(2) * 100 final_vector(3) * 100]

    %% Compose result
    compl_color = [];
    for x = 1 : DIM
        for y = 1 : DIM
            compl_color(x, y, 1) = final_vector(1);
            compl_color(x, y, 2) = final_vector(2);
            compl_color(x, y, 3) = final_vector(3);
        end
    end

    %% Show complementary color of cropped zone.
    compl_color = hsv2rgb(compl_color);

    outname = ['complement_' image_path];
    imwrite(compl_color, outname);
end
