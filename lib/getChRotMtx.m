function rotMtx = getChRotMtx(maxOrder, aziRad, chDefinition)
% Returns a CH rotation matrix
% Thomas Deppisch, 2023
numChs = 2*maxOrder+1;
rotMtx = zeros(numChs, numChs);
rotMtx(1,1) = 1;

% this all assumes ACN!
if strcmp(chDefinition,'real')
    for orderIdx = 1:maxOrder
        rotMtx(2*orderIdx, 2*orderIdx) = cos(orderIdx * aziRad);
        rotMtx(2*orderIdx, 2*orderIdx+1) = -sin(orderIdx * aziRad);
    
        rotMtx(2*orderIdx+1, 2*orderIdx) = sin(orderIdx * aziRad);
        rotMtx(2*orderIdx+1, 2*orderIdx+1) = cos(orderIdx * aziRad);
    end
else
    % rotation with complex valued CHs/SHs around z is very easy
    mTempVec = [-1:-1:-maxOrder; 1:maxOrder];
    mIdxVec = [0; mTempVec(:)]; % ACN
    rotMtx = diag(exp(1i*mIdxVec*aziRad));
end