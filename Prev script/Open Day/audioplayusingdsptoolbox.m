% clear all variables to begin with
clear all; clc; clf; drawnow;
            
% load the audio files


fprintf('R E A D Y...\n');
% apready = audioplayer(ready.dat,Fready);
% playblocking(apready);
%wavplay(ready.dat, Fready); % Please keep your eyes open while we get baseline

% number of passes to average for baseline
blPass = 10;

% number of passes for stimulus period
stPass = 20;

% total number of passes for the demo
totPass = 60;

% FieldTrip buffer source
filename = 'buffer://localhost:1972';

% read the header for the first time to determine number of channels and sampling rate
hdr = ft_read_header(filename, 'cache', true);

count      = 0;
prevSample = 0;
blocksize  = hdr.Fs;
chanindx   = 1:5; % all channels

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
freqs=500;
sampleFreq=44100;
dt=1/sampleFreq;
ti = 0:dt:0.5;
AP = dsp.AudioPlayer('SampleRate',sampleFreq, ...
			'QueueDuration',0.50,... 
            'BufferSize',512);

rawData = cell(1,totPass);
        
while (count < totPass)

  % determine number of samples available in buffer
  hdr = ft_read_header(filename, 'cache', true);   %%%% memory buffer of bci 2000

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
    rawData{count} = nextdat;

    [power(count,:),freq] = mtspectrumc(nextdat',params);
     
    alphapower=mean(power(count,8:15));
    disp(['displaying instantaneous alpha power in ', num2str(count)]); 
    disp(alphapower);
    
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
         drawnow;
    end
    
    audio(count,:)=sin(2*pi*(freqs+(alphapower*100))*ti);

    step(AP,audio(count,:)');
    


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
           
            fprintf('R E L A X...\n');           
          
        end
    
      
    if (count == stPass)
        fprintf('C O N C E N T R A T E...\n');
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

  end  
    end 
     
  end
   
          
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

% blPowerArray = mean(power(1:15,9:13),2);
% stPowerArray = mean(power(analysisRange,9:13),2);
% 
% changeArray = stPowerArray/mean(blPowerArray) - 1;
% 
% quot = 100*mean(changeArray);
% fluct = std(stPowerArray)/mean(stPowerArray);
% 
% % show a message box
% msgbox(['Your relaxation quotient is ' num2str(quot) ' % and your sustenance quotient is ' num2str(fluct)], 'EEG Demo', 'help');
% 
%      
% disp('end of experiment');

  
    




