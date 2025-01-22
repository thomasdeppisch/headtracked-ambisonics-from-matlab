function hoasig_rot = rotateShdSig(hoasig, yawRad, pitchRad, rollRad, basisType)
% Modified version from the one of the Higher Order Ambisonics Toolbox,
% allowing for complex basis functions and using radians.
% TD, 2024
%
%ROTATEHOA_N3D Rotate a HOA encoded sound scene, by yaw-pitch-roll angles.
% ROTATEHOA_N3D takes an input HOA signal set and according to a
% specified rotation of the coordinate system, returns the HOA signals
% on the rotated frame.
%
% The convention used is of a right-hand coordinate, active rotation, 
% yaw-pitch-roll convention, with yaw applied first, then pitch, then roll.
%
% The code requires the Spherical Harmonic transform library (for the 
% euler2rotationMatrix() and getSHrotMtx() function) found in:
%
% <https://github.com/polarch/Spherical-Harmonic-Transform>
%
% For more information on the rotations in the SH domain, and the specific 
% implementation, check the documentation of the above library.
%
% Inputs:   
%   hoasig: HOA signals, N3D, ACN normalization and channel ordering
%   yaw:    yaw angle in degrees, around z (first rotation)
%   pitch:  pitch angle in degrees, around y' (second rotation)
%   roll:   roll angle in degrees, around x'' (third rotation)
% Outputs:
%   bfsig_rot:  rotated HOA signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Archontis Politis, 15/11/2015
%   archontis.politis@aalto.fi
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get order
Nchan = size(hoasig,2);
Nord = sqrt(Nchan)-1;

% get rotation matrix
Rzyx = euler2rotationMatrix(-yawRad, -pitchRad, rollRad, 'zyx');

% compute rotation matrix in the SH domain
Rshd = getSHrotMtx(Rzyx, Nord, basisType);

% apply to hoa signals
hoasig_rot = hoasig * Rshd.';

end
