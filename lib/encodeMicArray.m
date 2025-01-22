function encdSig = encodeMicArray(order, inMtx, fs, applyRadialFiltering, smaDesignAziZenRad, arrayRadius, arrayType, basisType)

if size(smaDesignAziZenRad, 2) == 2 % spherical array -> SHs
    Y=getSH(order, [smaDesignAziZenRad(:,1), smaDesignAziZenRad(:,2)], basisType);
elseif size(smaDesignAziZenRad, 2) == 1 % assume EMA -> CHs
    Y=getCH(order, smaDesignAziZenRad, basisType);
end

Enc=pinv(Y);
Enc=Enc/max(abs(Enc(:))) * 0.5;

encdSig = inMtx * Enc';

if applyRadialFiltering
    if size(smaDesignAziZenRad, 2) == 1
        error('No radial filter for EMA available!')
    end

    params.smaRadius = arrayRadius;
    params.arrayType = arrayType;
    params.fs = fs;
    params.order = order;
    params.nfft = 512;
    params.regulConst = 1e-4;
    encdSig = applyRadialFilter(encdSig, params);
end