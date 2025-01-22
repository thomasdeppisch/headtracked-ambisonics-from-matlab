function chSigRot = rotateChdSig(chSig, yawRad, basisType)
% Rotate CH-domain signal

numChannels = size(chSig,2);
maxOrder = (numChannels-1)/2;

Rshd = getChRotMtx(maxOrder, -yawRad, basisType);
chSigRot = chSig * Rshd.';


