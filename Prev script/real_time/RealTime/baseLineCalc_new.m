%PLOT BASELINE RAW POWER SPECTRUM AND LOG POWERSPECTRUM
%% clear all variables to begin with and init
function [mLogBL,blCount] =baseLineCalc_new(blPass,handles,currchan)
cla(handles.axes3);
cla(handles.axes2);
% display('inside baselinecalc ishandle(handles.axes2)');
% display(ishandle(handles.axes2));

currchan=str2num(currchan);
pause(1);
% if or(~isnumeric(currchan),currchan<0)
% currchan=2;
% end

fprintf('R E A D Y...\n');


if(~blPass)% number of passes to average for baseline
    blPass = 15;
end
blPass=str2num(blPass);

cfg.host='10.120.241.77';
cfg.port=(51244);
if ~isfield(cfg, 'host'),               cfg.host = 'eeg002';                              end
if ~isfield(cfg, 'port'),               cfg.port = 51244;                                 end % 51244 is for 32 bit, 51234 is for 16 bit
if ~isfield(cfg, 'channel'),            cfg.channel = 'all';                              end
if ~isfield(cfg, 'feedback'),           cfg.feedback = 'no';                              end
if ~isfield(cfg, 'target'),             cfg.target = [];                                  end
if ~isfield(cfg.target, 'datafile'),    cfg.target.datafile = 'buffer://localhost:1972';  end
if ~isfield(cfg.target, 'dataformat'),  cfg.target.dataformat = [];                       end % default is to use autodetection of the output format
if ~isfield(cfg.target, 'eventfile'),   cfg.target.eventfile = 'buffer://localhost:1972'; end
if ~isfield(cfg.target, 'eventformat'), cfg.target.eventformat = [];                      end % default is to use autodetection of the output format


sock = pnet('tcpconnect', cfg.host, cfg.port);
hdr = [];
flag=1;
while isempty(hdr)
    % read the message header
    msg       = [];
    msg.uid   = tcpread_new(sock, 16, 'uint8',1);
    msg.nSize = tcpread_new(sock, 1, 'int32',0);
    msg.nType = tcpread_new(sock, 1, 'int32',0);
    
    % read the message body
    switch msg.nType
        case 1
            % this is a message containing header details
            msg.nChannels         = tcpread_new(sock, 1, 'int32',0);
            msg.dSamplingInterval = tcpread_new(sock, 1, 'double',0);
            msg.dResolutions      = tcpread_new(sock, msg.nChannels, 'double',0);
            for i=1:msg.nChannels
                msg.sChannelNames{i} = tcpread_new(sock, char(0), 'char',0);
            end
            
            % convert to a fieldtrip-like header
            hdr.nChans  = msg.nChannels;
            hdr.Fs      = 1/(msg.dSamplingInterval/1e6);
            hdr.label   = msg.sChannelNames;
            hdr.resolutions = msg.dResolutions;
            % determine the selection of channels to be transmitted
            cfg.channel = ft_channelselection(cfg.channel, hdr.label);
            chanindx = match_str(hdr.label, cfg.channel);
            % remember the original header details for the next iteration
            hdr.orig = msg;
            
        otherwise
            % skip unknown message types
            % error('unexpected message type from RDA (%d)', msg.nType);
    end
end
%count      = 0;
blCount = blPass;
% prevSample = 0;
% blocksize  = hdr.Fs;
chanindx   = 1:hdr.nChans; % all channels

params.tapers = [1 1]; % tapers
params.pad = -1; % no padding
params.Fs = hdr.Fs; % sampling frequency
params.trialave = 0; % average over trials
params.fpass = [0 150];
%% create the plots-color range
colorLimsRawTF = [-50 50];
colorLimsChangeTF = [-15 15];
count = 0;
X=[];
while (count < blPass)
    %while (true)
    % read the message header
    msg       = [];
    msg.uid   = tcpread_new(sock, 16, 'uint8',0);
    msg.nSize = tcpread_new(sock, 1, 'int32',0);
    msg.nType = tcpread_new(sock, 1, 'int32',0);
    % read the message body
    switch msg.nType
        case 2
            % this is a 16 bit integer data block
            msg.nChannels     = hdr.orig.nChannels;
            msg.nBlocks       = tcpread_new(sock, 1, 'int32',0);
            msg.nPoints       = tcpread_new(sock, 1, 'int32',0);
            %msg.nPoints  =hdr.Fs;
            msg.nMarkers      = tcpread_new(sock, 1, 'int32',0);
            msg.nData         = tcpread_new(sock, [msg.nChannels msg.nPoints], 'int16',0);
            for i=1:msg.nMarkers
                msg.Markers(i).nSize      = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPosition  = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPoints    = tcpread_new(sock, 1, 'int32',0);
                % msg.Markers(i).nPoints   =hdr.Fs;
                msg.Markers(i).nChannel   = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).sTypeDesc  = tcpread_new(sock, char(0), 'char',0);
            end
            
        case 4
            % this is a 32 bit floating point data block
            msg.nChannels     = hdr.orig.nChannels;
            msg.nBlocks       = tcpread_new(sock, 1, 'int32',0);
            msg.nPoints       = tcpread_new(sock, 1, 'int32',0);
            %msg.nPoints=hdr.Fs;
            msg.nMarkers      = tcpread_new(sock, 1, 'int32',0);
            msg.fData         = tcpread_new(sock, [msg.nChannels msg.nPoints], 'single',0);
            
            for i=1:msg.nMarkers
                msg.Markers(i).nSize      = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPosition  = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPoints    = tcpread_new(sock, 1, 'int32',0);
                %msg.Markers(i).nPoints   =hdr.Fs;
                msg.Markers(i).nChannel   = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).sTypeDesc  = tcpread_new(sock, char(0), 'char',0);
            end
            
        case 3
            % acquisition has stopped
            break
            
        otherwise
            % ignore all other message types
    end
    
    % convert the RDA message into data and/or events
    dat   = [];
    event = [];
    
    if msg.nType==2 && msg.nPoints>0
        % FIXME should I apply the calibration here?
        dat = msg.nData(chanindx,:);
    end
    
    if msg.nType==4 && msg.nPoints>0
        % FIXME should I apply the calibration here?
        dat = msg.fData(chanindx,:);
    end
    
    if (msg.nType==2 || msg.nType==4) && msg.nMarkers>0
        % FIXME convert the message to events
    end
    dat;
    % Define markers struct and read markers
    
    
    %% while loop
    %ff=0;
    if ~isempty(dat)
        X=[X dat];
        [~,colum]=size(X);
        %ff=1;
        
        if((colum==500))
            count       = count + 1;
            blCount     = blCount - 1;
            nextdat=single(X);
            %             nextdat_freq=fft(nextdat);
            %             f_1=0:100;
            %             plot(f_1,nextdat_freq)
            %
            X=[];
            nextdat=nextdat(currchan,:);
            [power(count,:,:),freq] = mtspectrumc(nextdat',params);
            
            
            if (count > 1)
                %% plot the raw  BL TF spectrum continously
                
                hRawSpectrum=handles.axes2;
                %sqpow=squeeze(power(:,:,currchan));
                sqpow=power;
                caxis(hRawSpectrum,'auto');
                
                hold on;
                pcolor(hRawSpectrum,1:size(power,1), freq, double(sqpow'));
                shading interp;
                ylim(hRawSpectrum, [0  120]);
                
                
                %       plot(hRawSpectrum, timeRange, alphaUpperLimit, 'k--');
                %          plot(hRawSpectrum, timeRange, alphaLowerLimit, 'k--');
                xlabel(hRawSpectrum, 'Time (s)'); ylabel(hRawSpectrum, 'Frequency');
                %          xlim(hRawSpectrum, [1 blPass]);
                
                title(hRawSpectrum, 'Time Frequency Plot');
                %caxis(hRawSpectrum, colorLimsRawTF);
                
                hold on;
                colorbar('peer',hRawSpectrum);
                shading(hRawSpectrum, 'interp');
                drawnow;
                
            end
            
            % calculate power in various bands (baseline/test)
            if (blCount >= 0)
                %% plot the log BL power continuously(thin line)
                cla(handles.axes3)
                hBaseline=handles.axes3;
                sz=size(power);
                %powcol=squeeze(power(count,:,currchan));
                powcol=power(count,:);
                plot(hBaseline,freq, log10(powcol), 'color',[0.7 0.7 0.7]);
                xlabel(hBaseline, 'Frequency (Hz)'); ylabel(hBaseline, 'Log(Baseline Power(dB))');
                %         title(hBaseline, 'Log(Baseline power)');
                %xlim(hBaseline,[0 blPass]);
                xlim(hBaseline,[0 120]);
                %             ylim(hBaseline,colorLimsRawTF);
                ylim(hBaseline,[0 10]);
                
                %%
                if (blCount == 0)
                    mLogBL = mean(log10(sqpow));
                    
                    %                     for kk=1:count
                    %                        %dPower(kk,:) = log10(squeeze(power(kk,:,currchan))) - mLogBL;
                    %                        dPower(kk,:) = log10((power(kk,:))) - mLogBL;
                    %
                    %                     end
                    %% log(bl power)THICK
                    cla(handles.axes3)
                    axes(hBaseline);
                    constchanpow=mean(log10(squeeze(sqpow)));
                    plot(freq, constchanpow, 'k','linewidth',3);
                    xlabel(hBaseline, 'Frequency (Hz)'); ylabel(hBaseline, 'Log(Baseline Power(dB))');
                    title(hBaseline, 'Log(Baseline power)');
                    xlim(hBaseline, [0 120]);
                    ylim(hBaseline,[0 10]);
                    %%
                    % cue user's attention
                    fprintf('R E L A X...\n');
                    
                end
                
                continue;
                
            end
        end
    end
    
end
pnet(sock,'close');
end % while true % while true
