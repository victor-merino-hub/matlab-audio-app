function [file, path] = uigetfile(varargin)
%UIGETFILE Demo-only replacement for the file dialog.
%   make_demo.m puts this folder first on the path so that the app's "Load"
%   button opens the sample file in DEMO_AUDIO_FILE without user interaction.
f = getenv('DEMO_AUDIO_FILE');
[path, name, ext] = fileparts(f);
file = [name ext];
path = [path filesep];
end
