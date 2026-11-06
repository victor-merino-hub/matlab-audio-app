function make_demo
%MAKE_DEMO Runs the app without user interaction and saves screenshots + an animated GIF.
%   Run from the repository root:   matlab -batch "addpath('demo'); make_demo"
%   Needs MATLAB R2023a or later with the Signal Processing Toolbox.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
outDir = fullfile(here, 'screenshots');
if ~exist(outDir, 'dir'), mkdir(outDir); end

addpath(fullfile(root, 'app'));
addpath(fullfile(here, 'shim'));            % shadows uigetfile (see shim/uigetfile.m)
warning('off', 'MATLAB:dispatcher:nameConflict');

% Sample speech recording that ships with MATLAB (generated at run time, not stored in the repo)
candidates = {'SpeechDFT-16-8-mono-5secs.wav', 'Counting-16-44p1-mono-15secs.wav'};
sample = '';
for k = 1:numel(candidates)
    if ~isempty(which(candidates{k})), sample = which(candidates{k}); break; end
end
if isempty(sample)                          % fallback: Handel excerpt (base MATLAB)
    S = load('handel.mat'); sample = fullfile(tempdir, 'handel.wav');
    audiowrite(sample, S.y, S.Fs);
end
setenv('DEMO_AUDIO_FILE', sample);

app = InterfazGrafSonido;
app.UIFigure.WindowState = 'normal';
app.UIFigure.Position = [20 20 1600 820];
frames = {};

    function snap(name)
        drawnow; pause(1);
        f = fullfile(outDir, [name '.png']);
        exportapp(app.UIFigure, f);
        frames{end+1} = imread(f);
        fprintf('saved %s\n', f);
    end
    function press(btn)
        btn.ButtonPushedFcn(btn, []);       % same callback the button runs when clicked
    end

snap('01_start');

% 1) Generate a 200 Hz square wave by additive (Fourier) synthesis: 20 odd harmonics
app.TipoDropdown.Value = 'Cuadrada';
app.frecuenciaField.Value = 200;
app.amplitudField.Value = 1;
app.frecmuestrField.Value = 16000;          % highest harmonic (7.8 kHz) stays below Fs/2
app.duracionField.Value = 0.05;
press(app.GenerarsealButton);
snap('02_square_wave');

% 2) Magnitude spectrum: odd harmonics at 200, 600, 1000 Hz... with 1/k amplitude
app.Switch.Value = 'Frecuencia';
app.Switch.ValueChangedFcn(app.Switch, []);
snap('03_square_spectrum');

% 3) Load a speech recording: waveform + spectrogram
app.Switch.Value = 'Espectrograma';
press(app.Button);
app.Switch.ValueChangedFcn(app.Switch, []);
snap('04_loaded_speech');

% 4) Time compression x1.5: the processed version is shorter and its spectrum moves up
app.factordecompresion.Value = 1.5;
app.opcionesdeprocesado.Value = 'Compresion';
press(app.ProcesarsealButton);
snap('05_speech_compressed');

% Animated GIF for the README
gifFile = fullfile(here, 'demo.gif');
for k = 1:numel(frames)
    img = imresize(frames{k}, 0.6);
    [ind, map] = rgb2ind(img, 256);
    if k == 1
        imwrite(ind, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', 2.5);
    else
        imwrite(ind, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', 2.5);
    end
end
fprintf('saved %s\n', gifFile);

delete(app);
end
