

function imageEnlarged = enlargeImageByMaskHorizontal(image, seamMask)

    imageEnlarged = zeros(size(image, 1) + 1, size(image, 2), size(image, 3));
    for j = 1 : size(seamMask, 2)
        i = find(seamMask(:, j) ~= 1);
            imageEnlarged(:, j, 1) = [image(1:i, j, 1); image(i, j, 1); image(i+1:end, j, 1)];
            imageEnlarged(:, j, 2) = [image(1:i, j, 2); image(i, j, 2); image(i+1:end, j, 2)];
            imageEnlarged(:, j, 3) = [image(1:i, j, 3); image(i, j, 3); image(i+1:end, j, 3)];
    end
end
