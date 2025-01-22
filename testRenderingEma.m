clear all
close all

% This script demonstrates the binaural rendering of Ambisonics audio from
% MATLAB using headtracker data.
% Rendering of signals from an Equatorial Microphone Array (EMA) using eMagLS.

addpath(genpath('./dependencies'))
addpath(genpath('./lib'))

%% choose rendering parameters
loopLenSec = 10;
localPortUdp = 8000; % UDP port to receive headtracker data
samplesPerFrame = 256; % increase this if you experience dropouts, decrease to update the rendering faster

order = 4;
sigLenSec = 5;
fs = 48000;

%% load rir
basisType = 'real';
harmonicsType = 'SHs';

rirStruct = load("resources/rirSimEma_8cm_60ch_rigid_8x6x4m_278ms.mat");

sig = 2 * rand(sigLenSec*fs,1) - 1;
%sig = audioread('decemberTour.wav');
arraySig = fftfilt(rirStruct.rir, sig);

% encode array signal
Y = getCH(order, rirStruct.micsAziZenRad(:,1), basisType);
harmSig = arraySig * pinv(Y.');

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

% extract horizontal HRIRs
horIdx = abs((pi/2-hrirGridZenRad)*180/pi) < 1;
hrirGridHorAziRad = hrirGridAziRad(horIdx);
hLHor = hL(:,horIdx);
hRHor = hR(:,horIdx);

switch harmonicsType
    case 'SHs'
        [decodingFiltersLeft, decodingFiltersRight] = getEMagLsFiltersEMAinSH(hL, hR, hrirGridAziRad, hrirGridZenRad, ...
                                                        rirStruct.smaRadius, rirStruct.micsAziZenRad(:,1), order, fs, filterLen, basisType);

        % convert to SHs
        J = getChToShExpansionMatrix(order, basisType);
        renderSig = harmSig * J.';

    case 'CHs'
        [decodingFiltersLeft, decodingFiltersRight] = getEMagLsFiltersEMAinCH(hLHor, hRHor, hrirGridHorAziRad, pi/2*ones(size(hrirGridHorAziRad)), ...
                                                        rirStruct.smaRadius, rirStruct.micsAziZenRad(:,1), order, fs, filterLen, basisType);

        renderSig = harmSig;        
end


%% start rendering loop
normalizer = max(abs(sum(fftfilt(decodingFiltersLeft,renderSig),2)));

audioUnderruns = renderHeadTrackedAmbisonics(renderSig./normalizer*0.1, loopLenSec, fs, ...
                          decodingFiltersLeft, decodingFiltersRight, localPortUdp, ...
                          samplesPerFrame, harmonicsType, basisType);
