function [alphaData betaData gammaData ]=bandpassfilt_alpha(nextDat)
%BANDPASSFILT_ALPHA Filters input x and returns output y.

in1=input('Enter the sampling frequency in Hz ');
in2=input('Enter the alpha range ');
in3=input('Enter the beta range ');
in4=input('Enter the gamma range ');
hd1 = designfilt('bandpassiir', ...       % Response type
    'StopbandFrequency1',in2(1)-2, ...    % Frequency constraints
    'PassbandFrequency1',in2(1), ...
    'PassbandFrequency2',in2(2), ...
    'StopbandFrequency2',in2(2)+2, ...
    'StopbandAttenuation1',40, ...   % Magnitude constraints
    'PassbandRipple',1, ...
    'StopbandAttenuation2',50, ...
    'DesignMethod','butter', ...      % Design method
    'MatchExactly','passband', ...   % Design method options
    'SampleRate',in1);            % Sample rate

hd2 = designfilt('bandpassiir', ...       % Response type
    'StopbandFrequency1',in3(1)-2, ...    % Frequency constraints
    'PassbandFrequency1',in3(1), ...
    'PassbandFrequency2',in3(2), ...
    'StopbandFrequency2',in3(2)+2, ...
    'StopbandAttenuation1',40, ...   % Magnitude constraints
    'PassbandRipple',1, ...
    'StopbandAttenuation2',50, ...
    'DesignMethod','butter', ...      % Design method
    'MatchExactly','passband', ...   % Design method options
    'SampleRate',in1)    ;           % Sample rate
hd3 = designfilt('bandpassiir', ...       % Response type
    'StopbandFrequency1',in4(1)-2, ...    % Frequency constraints
    'PassbandFrequency1',in4(1), ...
    'PassbandFrequency2',in4(2), ...
    'StopbandFrequency2',in4(2)+2, ...
    'StopbandAttenuation1',40, ...   % Magnitude constraints
    'PassbandRipple',1, ...
    'StopbandAttenuation2',50, ...
    'DesignMethod','butter', ...      % Design method
    'MatchExactly','passband', ...   % Design method options
    'SampleRate',in1)  ;             % Sample rate




alphaData = filter2(hd1.Coefficients,nextDat);
betaData = filter2(hd2.Coefficients,nextDat);
gammaData = filter2(hd3.Coefficients,nextDat);


end