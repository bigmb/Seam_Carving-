clc
close all 
clear

image = imread('orange.jpeg');

image = im2double(image);
fprintf('Size of original image is: ');
size(image)

l = input('\n enter the length: ');
b = input('\n enter the new bredth: ');
newSize = [l b]; % apply seam carving to the image


image_output = seamCarving(newSize, image);

figure()
imshow(image)
title('Original Image');

figure()
imshow(image_output)
title('Modified Image');

fprintf('Size of modified image is: ');
size(image_output)

function image = seamCarving(newSize, image)
% apply seam carving to the image
% following paper by Avidan and Shamir '07
    sizeReductionX = size(image, 1) - newSize(1);
    sizeReductionY = size(image, 2) - newSize(2);
    
    mmax = @(left, right) max([left right]);
    
    image = seamCarvingReduce([mmax(0, sizeReductionX), mmax(0, sizeReductionY)], image);
    
    image = seamCarvingEnlarge([mmax(0, -sizeReductionX), mmax(0, -sizeReductionY)], image);
end

function image = seamCarvingReduce(sizeReduction, image)
    if (sizeReduction == 0)
        return;
    end
    [~, transBitMask] = findTransportMatrix(sizeReduction, image); % find optimal order of removing raws and columns

    image = addOrDeleteSeams(transBitMask, sizeReduction, image, @reduceImageByMask);
end

function image = seamCarvingEnlarge(sizeEnlarge, image)
    if (sizeEnlarge == 0)
        return;
    end
    [~, transBitMask] = findTransportMatrix(sizeEnlarge, image);
    image = addOrDeleteSeams(transBitMask, sizeEnlarge, image, @enlargeImageByMask);
end

function [T, transBitMask] = findTransportMatrix(sizeReduction, image)
% find optimal order of removing raws and columns

    T = zeros(sizeReduction(1) + 1, sizeReduction(2) + 1, 'double');
    transBitMask = ones(size(T)) * -1;

    % fill in borders
    imageNoRow = image;
    for i = 2 : size(T, 1)
        energy = energyRGB(imageNoRow);
        [optSeamMask, seamEnergyRow] = findOptSeam(energy');
        imageNoRow = reduceImageByMask(imageNoRow, optSeamMask, 0);
        transBitMask(i, 1) = 0;

        T(i, 1) = T(i - 1, 1) + seamEnergyRow;
    end

    imageNoColumn = image;
    for j = 2 : size(T, 2)
        energy = energyRGB(imageNoColumn);
        [optSeamMask, seamEnergyColumn] = findOptSeam(energy);
        imageNoColumn = reduceImageByMask(imageNoColumn, optSeamMask, 1);
        transBitMask(1, j) = 1;

        T(1, j) = T(1, j - 1) + seamEnergyColumn;
    end

    % on the borders, just remove one column and one row before proceeding
    energy = energyRGB(image);
    [optSeamMask, ~] = findOptSeam(energy');
    image = reduceImageByMask(image, optSeamMask, 0);

    energy = energyRGB(image);
    [optSeamMask, ~] = findOptSeam(energy);
    image = reduceImageByMask(image, optSeamMask, 1);

    % fill in internal part
    for i = 2 : size(T, 1)

        imageWithoutRow = image; % copy for deleting columns

        for j = 2 : size(T, 2)
            energy = energyRGB(imageWithoutRow);

            [optSeamMaskRow, seamEnergyRow] = findOptSeam(energy');
            imageNoRow = reduceImageByMask(imageWithoutRow, optSeamMaskRow, 0);

            [optSeamMaskColumn, seamEnergyColumn] = findOptSeam(energy);
            imageNoColumn = reduceImageByMask(imageWithoutRow, optSeamMaskColumn, 1);

            neighbors = [(T(i - 1, j) + seamEnergyRow) (T(i, j - 1) + seamEnergyColumn)];
            [val, ind] = min(neighbors);

            T(i, j) = val;
            transBitMask(i, j) = ind - 1;

            % move from left to right
            imageWithoutRow = imageNoColumn;
        end

        energy = energyRGB(image);
        [optSeamMaskRow, ~] = findOptSeam(energy');
         % move from top to bottom
        image = reduceImageByMask(image, optSeamMaskRow, 0);
    end

end

function image = addOrDeleteSeams(transBitMask, sizeReduction, image, operation)
% delete seams following optimal way
    i = size(transBitMask, 1);
    j = size(transBitMask, 2);

    for it = 1 : (sizeReduction(1) + sizeReduction(2))

        energy = energyRGB(image);
        if (transBitMask(i, j) == 0)
            [optSeamMask, ~] = findOptSeam(energy');
            image = operation(image, optSeamMask, 0);
            i = i - 1;
        else
            [optSeamMask, ~] = findOptSeam(energy);
            image = operation(image, optSeamMask, 1);
            j = j - 1;
        end

    end
end

function [optSeamMask, seamEnergy] = findOptSeam(energy)
% finds optimal seam
% returns mask with 0 mean a pixel is in the seam
    % find M for vertical seams
    % for vertical - use I` ie transpose of the matrix
    M = zeros(size(energy,1),size(energy,2)+2);
    M(:,2:size(energy,2)+1) = energy;
    M(:,1)=1000;
    M(:,size(energy,2)+2)=1000;
    
    sz = size(M);
    for i = 2 : sz(1)
        for j = 2 : (sz(2) - 1)
            neighbors = [M(i - 1, j - 1) M(i - 1, j) M(i - 1, j + 1)];
            M(i, j) = M(i, j) + min(neighbors);
        end
    end
    % find the min element in the last raw
    [val, indJ] = min(M(sz(1), :));
    seamEnergy = val;
    
    optSeamMask = zeros(size(energy), 'uint8');  
     
    %go backward and save (i, j)
    for i = sz(1) : -1 : 2
        optSeamMask(i, indJ - 1) = 1; % -1 because of padding on 1 element from left 
        neighbors = [M(i - 1, indJ - 1) M(i - 1, indJ) M(i - 1, indJ + 1)];
        [val, indIncr] = min(neighbors);        
        seamEnergy = seamEnergy + val;
        indJ = indJ + (indIncr - 2); % To know the index of the above seam
    end

    optSeamMask(1, indJ - 1) = 1; % -1 because of padding on 1 element from left
    optSeamMask = ~optSeamMask;
    
end

function imageReduced = reduceImageByMask( image, seamMask, isVerical )
% removes pixels by input mask
% removes vertical line if isVerical == 1, otherwise horizontal
    if (isVerical)
        imageReduced = reduceImageByMaskVertical(image, seamMask);
    else
        imageReduced = reduceImageByMaskHorizontal(image, seamMask');
    end
end

function imageReduced = reduceImageByMaskVertical(image, seamMask)
    imageReduced = zeros(size(image, 1), size(image, 2) - 1, size(image, 3));
    %size(image, 2) - 1
    for i = 1 : size(seamMask, 1)
        imageReduced(i, :, 1) = image(i, seamMask(i, :), 1);
        imageReduced(i, :, 2) = image(i, seamMask(i, :), 2);
        imageReduced(i, :, 3) = image(i, seamMask(i, :), 3);
    end
end

function imageReduced = reduceImageByMaskHorizontal(image, seamMask)
    imageReduced = zeros(size(image, 1) - 1, size(image, 2), size(image, 3));
    %size(image, 1) - 1
    for j = 1 : size(seamMask, 2)
        imageReduced(:, j, 1) = image(seamMask(:, j), j, 1);
        imageReduced(:, j, 2) = image(seamMask(:, j), j, 2);
        imageReduced(:, j, 3) = image(seamMask(:, j), j, 3);
    end
end

function imageEnlarged = enlargeImageByMask(image, seamMask, isVerical)
% removes pixels by input mask
% removes vertical line if isVerical == 1, otherwise horizontal
    if (isVerical)
        imageEnlarged = enlargeImageByMaskVertical(image, seamMask);
    else
        imageEnlarged = enlargeImageByMaskHorizontal(image, seamMask');
    end
end

function imageEnlarged = enlargeImageByMaskVertical(image, seamMask)

    imageEnlarged = zeros(size(image, 1), size(image, 2) + 1, size(image, 3));
    for i = 1 : size(seamMask, 1)
        j = find(seamMask(i, :) ~= 1);
            imageEnlarged(i, :, 1) = [image(i, 1:j, 1), image(i, j, 1), image(i, j+1:end, 1)];
            imageEnlarged(i, :, 2) = [image(i, 1:j, 2), image(i, j, 2), image(i, j+1:end, 2)];
            imageEnlarged(i, :, 3) = [image(i, 1:j, 3), image(i, j, 3), image(i, j+1:end, 3)];
    end
end

function imageEnlarged = enlargeImageByMaskHorizontal(image, seamMask)

    imageEnlarged = zeros(size(image, 1) + 1, size(image, 2), size(image, 3));
    for j = 1 : size(seamMask, 2)
        i = find(seamMask(:, j) ~= 1);
            imageEnlarged(:, j, 1) = [image(1:i, j, 1); image(i, j, 1); image(i+1:end, j, 1)];
            imageEnlarged(:, j, 2) = [image(1:i, j, 2); image(i, j, 2); image(i+1:end, j, 2)];
            imageEnlarged(:, j, 3) = [image(1:i, j, 3); image(i, j, 3); image(i+1:end, j, 3)];
    end
end

function res = energyRGB(I)
% returns energy of all pixels
% e = |dI/dx| + |dI/dy|
    res = energyGrey(I(:, :, 1)) + energyGrey(I(:, :, 2)) + energyGrey(I(:, :, 3));
end

function res = energyGrey(I)
% returns energy of all pixels
% e = |dI/dx| + |dI/dy|
    res = abs(imfilter(I, [-1,0,1], 'replicate')) + abs(imfilter(I, [-1;0;1], 'replicate'));
end