# Headtracked Ambisonics Rendering from MATLAB
This repository provides functions for the headtracked binaural rendering of Ambisonics audio with a [Supperware headtracker](https://supperware.co.uk/). 
See `testRenderingAnechoic.m` for an example rendering using MagLS, `testRenderingEma.m` for the rendering of EMA signals, and `testRenderingSma.m` for the rendering of SMA signals.

To get started, connect your Supperware headtracker, and set the Bridgehead software to `Quaternion (composite)` output. The scripts will expect to receive headtracker data on local port 8000.

This repository uses the [Spherical Harmonic Transform Library](https://github.com/polarch/Spherical-Harmonic-Transform) and the [eMagLS repository](https://github.com/thomasdeppisch/eMagLS.git). 
