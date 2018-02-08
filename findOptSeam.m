
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

