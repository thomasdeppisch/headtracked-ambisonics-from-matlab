clear all
close all

% This script demonstrates the binaural rendering of Ambisonics audio from
% MATLAB using headtracker data.
% Rendering of signals from a Spherical Microphone Array (SMA) using eMagLS.

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
rirStruct = load("resources/rirSimSma_8cm_32ch_rigid_8x6x4m_278ms.mat");

sig = 2 * rand(sigLenSec*fs,1) - 1;
%sig = audioread('decemberTour.wav');
arraySig = fftfilt(rirStruct.rir, sig);

% encode array signal
Y = getSH(order, rirStruct.micsAziZenRad, basisType);
shSig = arraySig * pinv(Y.');

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

[decodingFiltersLeft, decodingFiltersRight] = getEMagLsFilters(hL, hR, hrirGridAziRad, hrirGridZenRad, ...
                                        rirStruct.smaRadius, rirStruct.micsAziZenRad(:,1), rirStruct.micsAziZenRad(:,2),...
                                        order, fs, filterLen, basisType);


%% start rendering loop
normalizer = max(abs(sum(fftfilt(decodingFiltersLeft,shSig),2)));

audioUnderruns = renderHeadTrackedAmbisonics(shSig./normalizer*0.1, loopLenSec, fs, ...
                          decodingFiltersLeft, decodingFiltersRight, localPortUdp, ...
                          samplesPerFrame, 'SHs', basisType);
