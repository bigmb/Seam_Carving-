
function imageEnlarged = enlargeImageByMaskVertical(image, seamMask)

    imageEnlarged = zeros(size(image, 1), size(image, 2) + 1, size(image, 3));
    for i = 1 : size(seamMask, 1)
        j = find(seamMask(i, :) ~= 1);
            imageEnlarged(i, :, 1) = [image(i, 1:j, 1), image(i, j, 1), image(i, j+1:end, 1)];
            imageEnlarged(i, :, 2) = [image(i, 1:j, 2), image(i, j, 2), image(i, j+1:end, 2)];
            imageEnlarged(i, :, 3) = [image(i, 1:j, 3), image(i, j, 3), image(i, j+1:end, 3)];
    end
end

