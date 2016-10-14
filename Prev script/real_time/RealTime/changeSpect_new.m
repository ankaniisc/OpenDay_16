function changeSpect_new( mLogBL,handles,currchan, totPass,in)
% cla(handles.axes12);
% cla(handles.axes7);
% cla(handles.axes8);
% cla(handles.axes9);
%cla(handles.axes3);
pnet('closeall')
% if or(~isnumeric(currchan),currchan<0)
%     currchan=2;
% end
currchan=str2num(currchan);
totPass=str2num(totPass);
fprintf('R E A D Y...\n');

if ~exist('totPass')
    % total number of passes for the raw power spectrum
    totPass = 20;
end

% if isnan(handles.edit5)
%   set(handles.edit5,'String','8');
% end
al=str2double(get(handles.edit5,'String'));
au=str2double(get(handles.edit6,'String'));
%bl=str2double(get(handles.edit7,'String'));
%bu=str2double(get(handles.edit8,'String'));
%gl=str2double(get(handles.edit9,'String'));
%gu=str2double(get(handles.edit10,'String'));
alphaUpperLimit = repmat(au, 1, totPass+1);
alphaLowerLimit = repmat(al, 1, totPass+1);
%betaUpperLimit = repmat(bu, 1, totPass+1);
%betaLowerLimit = repmat(bl, 1, totPass+1);
%gammaUpperLimit = repmat(gu, 1, totPass+1);
%if (gammaUpperLimit(1)> 50)
%    gammaUpperLimit=repmat(50, 1, totPass+1);
%end
%gammaLowerLimit = repmat(gl, 1, totPass+1);

timeRange = linspace(0,totPass,totPass+1);
freqRange = linspace(0,50,51);

%% create the plots-color range
colorLimsRawTF = [-3 3];
colorLimsChangeTF = [-10 10];




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
in1=hdr.Fs;

params.tapers = [1 1]; % tapers
params.pad = -1; % no padding
params.Fs = hdr.Fs; % sampling frequency
params.trialave = 0; % average over trials
params.fpass = [0 150];

count = 0;
X=[];
%% while loop
while (count < totPass)
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
            %msg.nPoints       =hdr.Fs;
            msg.nMarkers      = tcpread_new(sock, 1, 'int32',0);
            msg.nData         = tcpread_new(sock, [msg.nChannels msg.nPoints], 'int16',0);
            for i=1:msg.nMarkers
                msg.Markers(i).nSize      = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPosition  = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).nPoints    = tcpread_new(sock, 1, 'int32',0);
                % msg.Markers(i).nPoints    =hdr.Fs;
                msg.Markers(i).nChannel   = tcpread_new(sock, 1, 'int32',0);
                msg.Markers(i).sTypeDesc  = tcpread_new(sock, char(0), 'char',0);
            end
            
        case 4
            % this is a 32 bit floating point data block
            msg.nChannels     = hdr.orig.nChannels;
            msg.nBlocks       = tcpread_new(sock, 1, 'int32',0);
            msg.nPoints       = tcpread_new(sock, 1, 'int32',0);
            % msg.nPoints       =hdr.Fs;
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
    msg;
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
    %ff=0;
    msg;
    if ~isempty(dat)
        X=[X dat];
       
       
        [~,col]=size(X);
        % ff=1;
        currchan;
        if((col==500))
             %cla(handles.axes9)
        axes(handles.axes9)
         t = 0:1/hdr.Fs:1-1/hdr.Fs;
         if rem(count,10)==0
             cla(handles.axes9);
         end
        plot(t+rem(count,10),(X(currchan,:)-mean(X(currchan,:))),'b');
        xlim([0 10]);
        ylim([-500 500]);
        hold(handles.axes9,'on')
            count       = count + 1;
            nextdat=single(X);
            %nextdat=nextdat(currchan,:);
            X=[];
            
            [power(count,:,:),freq] = mtspectrumc(nextdat',params);
            if (count > 1)
                %% plot the raw  BL TF spectrum continously
                hRawSpectrum=handles.axes2;
                %                     axes(hRawSpectrum);
                %                     sqpow=squeeze(power(:,:,currchan));
                %                     pcolor(1:size(power,1), freq, double(sqpow'));
                %                     shading interp;
                %                     plot(hRawSpectrum, timeRange, alphaUpperLimit, 'k--');
                %                     plot(hRawSpectrum, timeRange, alphaLowerLimit, 'k--');
                %                     xlabel(hRawSpectrum, 'Time (s)'); ylabel(hRawSpectrum, 'Frequency');
                %                     xlim(hRawSpectrum, [1 totPass]);
                %                     ylim(hRawSpectrum, [0 50]);
                %                     title(hRawSpectrum, 'Log (Raw power spectrum)');
                %                    % caxis(hRawSpectrum, colorLimsRawTF);
                %                    caxis(hRawSpectrum,[-30 30])
                %                     colorbar('peer',hRawSpectrum);
                %                    drawnow;
                
                %
                
                %             plot(handles.axes2, timeRange, alphaUpperLimit, 'k--');
                %             plot(handles.axes2, timeRange, alphaLowerLimit, 'k--');
               
                %xlim(handles.axes2, [1 totPass]);
               
                %title('Change in power spectrum');
                
                %% change in pow spectrum
               dPower = ([dPower; 10*double(log10(squeeze(power(count,:,currchan))) - mLogBL)]);
               clear dPowerAllElec;
               dPowerAllElec = squeeze(10*double(log10(power(count,:,:))-repmat(mLogBL,1,1,size(power,3)))); %%% Nextpower %%%
               %dPower = [dPower; log10((power(count,:))) - mLogBL];
               
                           
                axes(handles.axes2);
                %cla(handles.axes2);
                pcolor(1:size(dPower,1), freq, (dPower(1:size(dPower,1),:)'));
                shading interp;
                %pause(0.1)
                %cla(handles.axes2)
                title('Time Frequency Plot')
                 xlabel(handles.axes2, 'Time (s)'); ylabel(handles.axes2, 'Frequency');
                caxis(handles.axes2,[-20 20]);
                xlim(handles.axes2,[0 100]);
                 ylim(handles.axes2, [0 80]);
                colorbar('peer',hRawSpectrum);
            end
            if (count ==1)
                 dPower=10*(log10(squeeze(power(count,:,currchan))) - mLogBL);
                 %dPower=log10((power(count,:))) - mLogBL;
            end
            %% change in BL power(thin)
            %plots power Vs frequency
            cla(handles.axes3)
            axes(handles.axes3);
            plot(freq, 10*(log10(squeeze(power(count,:,currchan))) - mLogBL), 'color',[0.7 0.7 0.7]);
            %plot(freq, 10*(log10((power(count,:))) - mLogBL), 'color',[0.7 0.7 0.7]);
            xlabel(handles.axes3, 'Frequency (Hz)'); ylabel(handles.axes3, 'Change in Power(dB)');
            title(handles.axes3, 'Change in baseline power');
            xlim(handles.axes3, [0 120]);
            ylim(handles.axes3,[-50 50]);
            drawnow;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             cla(handles.axes9)
%             axes(handles.axes9)
%             nex=nextdat(currchan,:);
%             plot(nex
            %% TOPOPLOT
            if(count>1)
%                sqpow=squeeze(dPower(count,:,:));
               %sqpow=power(count,:);
                cla(handles.axes5);
                % alpha
                %pause(0.01)
                axes(handles.axes5);
                alphasqpow=dPowerAllElec(alphaLowerLimit:alphaUpperLimit,:);
               %alphasqpow=sqpow(alphaLowerLimit:alphaUpperLimit);
                alphatopopow=mean(alphasqpow,1);
                topoplot(alphatopopow,handles.locpath,'colormap','jet');
                title('Power in Frequerncy band');
                % caxis(handles.axes5, colorLim);
                caxis(handles.axes5,[-10 10]);
                colorbar('peer',handles.axes5);
                drawnow;
%                 % beta
%                 
%                 cla(handles.axes7);
%                 axes(handles.axes7);
%                 %xlabel(handles.axes7,'BETA POWER ');
%                 betasqpow=sqpow(betaLowerLimit:betaUpperLimit,:);
%                 betatopopow=mean(betasqpow);
%                 topoplot(betatopopow,handles.locpath,'colormap','jet');
%                 title('BETA')
%                 %caxis(handles.axes7, colorLim);
%                 caxis(handles.axes7,'auto');
%                 colorbar('peer',handles.axes7);
%                 drawnow;
%                 
%                 % gamma
%                 cla(handles.axes8);
%                 axes(handles.axes8);
%                 %title(handles.axes8,'GAMMA POWER');
%                 gammasqpow=sqpow(gammaLowerLimit:gammaUpperLimit,:);
%                 gammatopopow=mean(gammasqpow);
%                 topoplot(gammatopopow,handles.locpath,'colormap','jet');
%                 title('GAMMA');
%                 % caxis(handles.axes8, colorLim);
%                 caxis(handles.axes8,'auto');
%                 colorbar('peer',handles.axes8);
%                 in2=[al au];
%                 in3=[bl bu];
%                 in4=[gl gu];
%                 [alphaData, betaData ,gammaData]=bandpassfilt_all(nextdat,in1,in2,in3,in4);
%               %  ad=mean(alphaData,2);
%%%%                 adnew=mean(nextdat,2);
%                 bd=mean(betaData,2);
%                 gd=mean(gammaData,2);
%                 %         ad1=ad';
%                 %         bd1=bd';
%                 %         gd1=gd';
%                 %         realTimeDataAnalysis_new(handles, alphatopopow,  betatopopow, gammatopopow,in);
%                 %         realTimeDataAnalysis_new(handles, alphaData, betaData, gammaData,in);
%%%%%%              realTimeDataAnalysis_new1(handles,nextdat,in);
%                 % pause(0.01);
%             end
            end
            
            
            %end % while true
            %% change in BL POW THICK LINE
            if(count==totPass)
                cla(handles.axes3)
                hChange=handles.axes3;
                subplot(hChange);
                plot(freq,mean(dPower), 'k','linewidth',2);
                xlabel(hChange, 'Frequency (Hz)');
                ylabel(hChange, 'Change in Power(dB)');
                title(hChange, 'Change in baseline power');
                xlim(hChange, [0 120]);
                ylim(hChange,[-50 50]);
            end
        end
        %% reset figure
        %fprintf('THE END');
    end
end
pnet(sock,'close')
end

