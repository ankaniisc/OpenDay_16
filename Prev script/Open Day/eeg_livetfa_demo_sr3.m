% clear all variables to begin with
clear; clc; clf; drawnow;
            
% load the audio files
[ready.dat, Fready] = audioread('ready.wav');
[relax.dat, Frelax] = audioread('relax.wav');
[conc.dat, Fconc] = audioread('concentrate.wav');

fprintf('R E A D Y...\n');
ap = audioplayer(ready.dat,Fready);
play(ap);
%wavplay(ready.dat, Fready); % Please keep your eyes open while we get baseline

% number of passes to average for baseline
blPass = 15;

% number of passes for stimulus period
stPass = 75;

% total number of passes for the demo
totPass = 90;

% FieldTrip buffer source
filename = 'buffer://localhost:1972';

% read the header for the first time to determine number of channels and sampling rate
hdr = ft_read_header(filename, 'cache', true);

count      = 0;
prevSample = 0;
blocksize  = hdr.Fs;
chanindx   = 1:hdr.nChans; % all channels

params.tapers = [1 1]; % tapers
params.pad = -1; % no padding
params.Fs = hdr.Fs; % sampling frequency
params.trialave = 1; % average over trials
params.fpass = [0 50];

alphaUpperLimit = repmat(12, 1, totPass+1);
alphaLowerLimit = repmat(8, 1, totPass+1);
timeRange = linspace(0,totPass,totPass+1);
freqRange = linspace(0,50,51);

% create the plots
colorLimsRawTF = [-3 3];
colorLimsChangeTF = [-15 15];

hRawSpectrum = subplot('Position',[0.075 0.55 0.525 0.4]);
hold on;
plot(hRawSpectrum, timeRange, alphaUpperLimit, 'k--');
plot(hRawSpectrum, timeRange, alphaLowerLimit, 'k--');
xlabel(hRawSpectrum, 'Time (s)'); ylabel(hRawSpectrum, 'Frequency');
xlim(hRawSpectrum, [1 totPass]);
ylim(hRawSpectrum, [0 50]);
title(hRawSpectrum, 'Log (Raw power spectrum)');
caxis(hRawSpectrum, colorLimsRawTF);
colorbar('peer',hRawSpectrum);

hChangeSpectrum = subplot('Position',[0.075 0.05 0.525 0.4]);
hold on;
plot(hChangeSpectrum, timeRange, alphaUpperLimit, 'k--');
plot(hChangeSpectrum, timeRange, alphaLowerLimit, 'k--');
xlabel(hChangeSpectrum, 'Time (s)'); ylabel(hChangeSpectrum, 'Frequency');
xlim(hChangeSpectrum, [1 totPass]);
ylim(hChangeSpectrum, [0 50]);
title(hChangeSpectrum, 'Change in power spectrum (dB)');
caxis(hChangeSpectrum, colorLimsChangeTF);
colorbar('peer',hChangeSpectrum);

hBaseline = subplot('Position',[0.675 0.55 0.3 0.4]);
hold on;
xlabel(hBaseline, 'Frequency (Hz)'); ylabel(hBaseline, 'Log Power');
title(hBaseline, 'Log(Baseline power)');
ys = colorLimsRawTF(1):0.01:colorLimsRawTF(2);
plot(hBaseline,8+zeros(1,length(ys)),ys,'k--');
plot(hBaseline,12+zeros(1,length(ys)),ys,'k--');
xlim(hBaseline, [0 50]);
ylim(hBaseline,colorLimsRawTF);

hChange = subplot('Position',[0.675 0.05 0.3 0.4]);
hold on;
xlabel(hChange, 'Frequency (Hz)'); ylabel(hChange, 'Change in Power');
title(hChange, 'Change in baseline power');
ys2 = colorLimsChangeTF(1):0.01:colorLimsChangeTF(2);
plot(hChange,8+zeros(1,length(ys2)),ys2,'k--');
plot(hChange,12+zeros(1,length(ys2)),ys2,'k--');
xlim(hChange, [0 50]);
ylim(hChange,colorLimsChangeTF);

blCount = blPass;

while (count < totPass)

  % determine number of samples available in buffer
  hdr = ft_read_header(filename, 'cache', true);

  % see whether new samples are available
  newsamples = (hdr.nSamples*hdr.nTrials-prevSample);

  if newsamples>=blocksize

    % determine the samples to process
    begsample  = prevSample+1;
    endsample  = prevSample+blocksize ;

    % remember up to where the data was read
    prevSample  = endsample;
    count       = count + 1;
    blCount     = blCount - 1;
    fprintf('processing segment %d from sample %d to %d\n', count, begsample, endsample);

    % read data segment from buffer
    nextdat = ft_read_data(filename, 'header', hdr, 'begsample', begsample, 'endsample', endsample, 'chanindx', chanindx);

    [power(count,:),freq] = mtspectrumc(nextdat',params);

    % plot the raw TF spectrum continously
    if (count > 1)
        subplot(hRawSpectrum);
        pcolor(1:size(power,1), freq, double(power'));
        shading interp;
        plot(hRawSpectrum, timeRange, alphaUpperLimit, 'k--');
        plot(hRawSpectrum, timeRange, alphaLowerLimit, 'k--');
        xlabel(hRawSpectrum, 'Time (s)'); ylabel(hRawSpectrum, 'Frequency');
        xlim(hRawSpectrum, [1 totPass]);
        ylim(hRawSpectrum, [0 50]);
        title(hRawSpectrum, 'Log (Raw power spectrum)');
        caxis(hRawSpectrum, colorLimsRawTF);
        colorbar('peer',hRawSpectrum);
        
%         plot(hRawSpectrum, timeRange, alphaUpperLimit, 'k--');
%         plot(hRawSpectrum, timeRange, alphaLowerLimit, 'k--');
%         xlabel(hRawSpectrum, 'Time (s)'); ylabel(hRawSpectrum, 'Frequency');
%         xlim(hRawSpectrum, [1 totPass]);
%         ylim(hRawSpectrum, [0 50]);
%         caxis(hRawSpectrum, [-15 15]);
%         title(hRawSpectrum, 'Raw power spectrum');
%         colorbar('peer',hRawSpectrum);
        drawnow;
    end
    
    % calculate power in various bands (baseline/test)
    if (blCount >= 0)
        
        % plot the raw power spectrum continuously
        subplot(hBaseline);
        plot(freq, log10(power(count,:)), 'color',[0.7 0.7 0.7]);
        xlabel(hBaseline, 'Frequency (Hz)'); ylabel(hBaseline, 'Log Power');
        title(hBaseline, 'Log(Baseline power)');
        xlim(hBaseline, [0 50]);
        ylim(hBaseline,colorLimsRawTF);

        if (blCount == 0)
            mLogBL = mean(log10(power));
            
            for kk=1:count
                dPower(kk,:) = log10(power(kk,:)) - mLogBL;
            end

            subplot(hBaseline);
            plot(freq, mean(log10(power)), 'k','linewidth',4);
            xlabel(hBaseline, 'Frequency (Hz)'); ylabel(hBaseline, 'Log Power');
            title(hBaseline, 'Log(Baseline power)');
            xlim(hBaseline, [0 50]);
            ylim(hBaseline,colorLimsRawTF);

            % cue user's attention
            fprintf('R E L A X...\n');
            
            %wavplay(relax.dat, Frelax); % Relax now and close your eyes
            ap = audioplayer(relax.dat,Frelax);
            play(ap);
        end
        continue;
    end

    if (count == stPass)
        fprintf('C O N C E N T R A T E...\n');
        ap = audioplayer(conc.dat,Fconc);
        play(ap);
        %wavplay(conc.dat, Fconc); % Open your eyes and concentrate
    end
    
    dPower = [dPower; log10(power(count,:)) - mLogBL];
    subplot(hChangeSpectrum);
    %pcolor(blPass:size(dPower,1), freq, 10*double(dPower(blPass:size(dPower,1),:)'));
    pcolor(1:size(dPower,1), freq, 10*double(dPower(1:size(dPower,1),:)'));
    shading interp;
    plot(hChangeSpectrum, timeRange, alphaUpperLimit, 'k--');
    plot(hChangeSpectrum, timeRange, alphaLowerLimit, 'k--');
    xlabel(hChangeSpectrum, 'Time (s)'); ylabel(hChangeSpectrum, 'Frequency');
    xlim(hChangeSpectrum, [1 totPass]);
    ylim(hChangeSpectrum, [0 50]);
    caxis(hChangeSpectrum, colorLimsChangeTF);
    
    title(hChangeSpectrum, 'Change in power spectrum');

    subplot(hChange);
    plot(freq, 10*(log10(power(count,:)) - mLogBL), 'color',[0.7 0.7 0.7]);
    xlabel(hChange, 'Frequency (Hz)'); ylabel(hChange, 'Change in Power');
    title(hChange, 'Change in baseline power');
    xlim(hChange, [0 50]);
    ylim(hChange,colorLimsChangeTF);

    drawnow;

  end % if 
end % while true

subplot(hChange);
plot(freq, 10*mean(dPower), 'k','linewidth',4);
xlabel(hChange, 'Frequency (Hz)'); ylabel(hChange, 'Power');
title(hChange, 'Change in baseline power');
xlim(hChange, [0 50]);

% reset figure
fprintf('End of the demo');

% TODO: calculate

% Take power between analysisRange
analysisRange = 26:75;

blPowerArray = mean(power(1:15,9:13),2);
stPowerArray = mean(power(analysisRange,9:13),2);

changeArray = stPowerArray/mean(blPowerArray) - 1;

quot = 100*mean(changeArray);
fluct = std(stPowerArray)/mean(stPowerArray);

% show a message box
msgbox(['Your relaxation quotient is ' num2str(quot) ' % and your sustenance quotient is ' num2str(fluct)], 'EEG Demo', 'help');
