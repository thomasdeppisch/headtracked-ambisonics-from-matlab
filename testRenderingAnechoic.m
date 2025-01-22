clear all
close all

% This script demonstrates the binaural rendering of Ambisonics audio from
% MATLAB using headtracker data.

addpath(genpath('./dependencies'))
addpath(genpath('./lib'))

%% choose rendering parameters
loopLenSec = 10;
localPortUdp = 8000; % UDP port to receive headtracker data
samplesPerFrame = 256; % increase this if you experience dropouts, decrease to update the rendering faster

order = 5;
sigLenSec = 5;
fs = 48000;
sourceDirAziDeg = 90;
sourceDirEleDeg = 0;
basisType = 'real';
harmonicsType = 'SHs';

%% create an Ambisonics signal
sig = 2 * rand(sigLenSec*fs,1) - 1;

sourceDirAziZenRad = pi/180 * [sourceDirAziDeg, 90-sourceDirEleDeg];
switch harmonicsType
    case 'SHs'
        Y = conj(getSH(order, sourceDirAziZenRad, basisType));
    case 'CHs'
        Y = conj(getCH(order, sourceDirAziZenRad(1), basisType));
end
shSig = sig * Y;

%% load binaural rendering filters (MagLS)
[hrirFile, hrirUrl] = deal('resources/HRIR_L2702.mat', ...
    'https://zenodo.org/record/3928297/files/HRIR_L2702.mat');

fprintf('Downloading HRIR dataset ... ');
if isfile(hrirFile)
    fprintf('already exists ... skipped.\n');
else
    downloadAndExtractFile(hrirFile, hrirUrl);
end

load(hrirFile);
filterLen = 256;
hL = double(HRIR_L2702.irChOne);
hR = double(HRIR_L2702.irChTwo);
hrirGridAziRad = double(HRIR_L2702.azimuth.');
hrirGridZenRad = double(HRIR_L2702.elevation.'); % the elevation angles actually contain zenith data between 0..pi
fsHrtf = double(HRIR_L2702.fs);
assert(fs==fsHrtf)

switch harmonicsType
    case 'SHs'
        [decodingFiltersLeft, decodingFiltersRight] = getMagLsFilters(hL, hR, hrirGridAziRad, hrirGridZenRad, ...
                                                                      order, fs, filterLen, basisType);
    case 'CHs'
        % extract horizontal HRIRs
        horIdx = abs((pi/2-hrirGridZenRad)*180/pi) < 1;
        hrirGridHorAziRad = hrirGridAziRad(horIdx);
        hLHor = hL(:,horIdx);
        hRHor = hR(:,horIdx);
        [decodingFiltersLeft, decodingFiltersRight] = getMagLsFilters2D(hLHor, hRHor, hrirGridHorAziRad, ...
                                                                      order, fs, filterLen, basisType);
end

% binauralOut = binauralDecode(shSig./max(abs(shSig(:)))*0.1, fs, decodingFiltersLeft, decodingFiltersRight, fs, false);
% soundsc(binauralOut,fs)


%% start rendering loop
audioUnderruns = renderHeadTrackedAmbisonics(shSig./max(abs(shSig(:)))*0.1, loopLenSec, fs, ...
                          decodingFiltersLeft, decodingFiltersRight, localPortUdp, ...
                          samplesPerFrame, harmonicsType, basisType);

