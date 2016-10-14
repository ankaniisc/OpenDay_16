function realTimeDataAnalysis_new(handles,alphaData,in)
% Collects EEG data for the specified duration and generates PSD plots
% for specified electrode(s) in real time.
% gridMontage = 'chan32';
% chanlocs = loadChanLocs(gridMontage);
    load('saved_gdh');

    chanlocs=in;
% Plotting CSD of alpha EEG data:
   % [ma,na]=size(alphaData);
  %  alphaData1=alphaData';
%     Xalpha = CSD (alphaData, G(1:ma,1:na), H(1:ma,1:na));
    Xalpha = CSD (alphaData, G, H);
    Xialpha = mean(Xalpha,2);
    
    %Scalpmap of  alpha CSD:
   
    axes(handles.axes9);
    cla(handles.axes9);
    topoplot(Xialpha,chanlocs,'colormap','jet');
    title('Alpha CSD')
    caxis(handles.axes9,'auto');
    colorbar('peer',handles.axes9);
    
    % CSD of beta data
   % [mb,nb]=size(betaData);
   % betaData1=betaData';
%     Xbeta=CSD (betaData, G, H);
%     Xibeta = mean(Xbeta,2);
%     axes(handles.axes10);
%     cla(handles.axes10);
%     topoplot(Xibeta,chanlocs,'colormap','jet');
%     title('Beta CSD')
%     caxis(handles.axes10,'auto');
%     colorbar('peer',handles.axes10);
% 
%     %plot gamma data
%    % [mg,ng]=size(gammaData);
%     %gammaData1=gammaData';
%     Xgamma=CSD (gammaData, G, H);
%     Xigamma=mean(Xgamma,2);
%     %gamma CSD
% 
%     axes(handles.axes11);
%         cla(handles.axes11);
%     topoplot(Xigamma,chanlocs,'colormap','jet');
%     title('Gamma CSD')
%     caxis(handles.axes11,'auto');
%     colorbar('peer',handles.axes11);

    

    
end