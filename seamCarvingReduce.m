function image = seamCarvingReduce(sizeReduction, image)
    if (sizeReduction == 0)
        return;
    end
    [~, transBitMask] = findTransportMatrix(sizeReduction, image); % find optimal order of removing raws and columns

    image = addOrDeleteSeams(transBitMask, sizeReduction, image, @reduceImageByMask);
end