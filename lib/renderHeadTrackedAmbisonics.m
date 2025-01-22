function audioUnderruns = renderHeadTrackedAmbisonics(ambiSig, loopLenSec, fs, ...
                          decodingFiltersLeft, decodingFiltersRight, localPortUdp, ...
                          samplesPerFrame, harmonicsType, basisType)

arguments
    ambiSig (:,:) % time x channels, assumes ACN ordering
    loopLenSec (1,1) % how many seconds to run the rendering loop
    fs (1,1) % sample rate
    decodingFiltersLeft (:,:) % matrix of rendering filters for left ear, e.g. obtained via MagLS
    decodingFiltersRight (:,:)
    localPortUdp (1,1) % UDP port to receive head-tracker data
    samplesPerFrame (1,1) % frame size, trade-off between computational demand and smoothness of rendering
    harmonicsType {mustBeMember(harmonicsType,{'SHs','CHs'})} % choose SHs or CHs
    basisType {mustBeMember(basisType,{'real','complex'})} % choose real or complex-valued harmonics
end

if strcmpi(basisType,'complex')
    ambiSig = ambiSig + eps*1i; % make sure that the signal is always complex otherwise the FIR filters throw an error
end

sigsrc = dsp.SignalSource(ambiSig, ...
    'SamplesPerFrame',samplesPerFrame, ...
    'SignalEndAction','Cyclic repetition');

deviceWriter = audioDeviceWriter('SampleRate',fs);
numChannels = size(ambiSig,2);

FIRLeft = cell(numChannels,1);
FIRRight = cell(numChannels,1);
for ii = 1:numChannels
    FIRLeft{ii} = dsp.FIRFilter(decodingFiltersLeft(:,ii).');
    FIRRight{ii} = dsp.FIRFilter(decodingFiltersRight(:,ii).');
end

% initialize rotation matrix
switch harmonicsType
    case 'SHs'
        rotateFun = @(sig_,yawPitchRollRad_) rotateShdSig(sig_, yawPitchRollRad_(1), yawPitchRollRad_(2), yawPitchRollRad_(3), basisType);

    case 'CHs'
        rotateFun = @(sig_,yawRad_) rotateChdSig(sig_, yawRad_(1), basisType);
end

% processing loop
audioUnderruns = 0;
u = dsp.UDPReceiver;
u.LocalIPPort = localPortUdp;


% pause(1) % this may increase the chance of a dropout-free rendering

tic
yaw = 0;
pitch = 0;
roll = 0;
while toc < loopLenSec
    dataReceived = u();
    if ~isempty(dataReceived) && length(dataReceived)==36
        % take only the last 16 bytes (the quaternions in raw floating-point format)
        nums = dataReceived(21:end);
        nums = fliplr(reshape(nums, 4, [])');
        quat = typecast(reshape(nums',16,[])', 'single');
        
        [yaw,pitch,roll] = quat2euler(double(quat));
        % disp([yaw,pitch,roll])
    end

    audioIn = sigsrc();

    % apply rotation
    sigRot = rotateFun(audioIn, [-yaw;-pitch;roll]);

    % decode
    audioFiltered = zeros(sigsrc.SamplesPerFrame,2);
    for ii = 1:numChannels
        audioFiltered(:,1) = audioFiltered(:,1) + FIRLeft{ii}(sigRot(:,ii));
        audioFiltered(:,2) = audioFiltered(:,2) + FIRRight{ii}(sigRot(:,ii));
    end

    if any(abs(real(audioFiltered)) > 1, 'all')
        warning('audio clipped')
    end

    audioUnderruns = audioUnderruns + deviceWriter(real(audioFiltered)); 
end

% cleanup
release(sigsrc)
release(deviceWriter)
release(u)
