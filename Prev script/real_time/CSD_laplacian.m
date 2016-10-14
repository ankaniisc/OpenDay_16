
% This Programme would take the volatge values of the equavalent electrodes
% and calculate the surface laplacian and plot it.

% dp = mean(nextdat,2); 
Fp1 = (dp(1)- mean([dp(3) dp(4) dp(5) dp(2)]));
Fp2 = (dp(2)- mean([dp(1) dp(5) dp(6) dp(7)]));
F7 = (dp(3)-  mean([dp(12) dp(8) dp(4) dp(1)]));
F3 = (dp(4)-  mean([dp(1) dp(8) dp(3) dp(9)]));
Fz = (dp(5)-  mean([dp(4) dp(10) dp(9) dp(6)]));
F4 = (dp(6)-  mean([dp(5) dp(11) dp(10) dp(7)]));
F8 = (dp(7)-  mean([dp(2) dp(16) dp(6) dp(11)]));
FC5 = (dp(8)- mean([dp(3) dp(13) dp(12) dp(4)]));
FC1 = (dp(9)- mean([dp(4) dp(14) dp(13) dp(5)]));
FC2 = (dp(10)- mean([dp(5) dp(15) dp(14) dp(6)]));
FC6 = (dp(11)- mean([dp(6) dp(16) dp(15) dp(7)]));
T7 = (dp(12)- mean([dp(18) dp(13) dp(17) dp(8)]));
C3 = (dp(13)- mean([dp(8) dp(19) dp(18) dp(9)]));
Cz = (dp(14)- mean([dp(9) dp(20) dp(19) dp(10)]));
C4 = (dp(15)- mean([dp(10) dp(21) dp(20) dp(11)]));
T8 = (dp(16)- mean([dp(11) dp(15) dp(21) dp(22)]));
TP9 = (dp(17)- mean([dp(12) dp(18) dp(23) dp(28)]));
CP5 = (dp(18)- mean([dp(12) dp(18) dp(23) dp(13)]));
CP1 = (dp(19)- mean([dp(13) dp(25) dp(24) dp(14)]));
CP2 = (dp(20)- mean([dp(14) dp(26) dp(25) dp(15)]));
CP6 = (dp(21)- mean([dp(15) dp(27) dp(26) dp(16)]));
TP10 = (dp(22)- mean([dp(16) dp(21) dp(27) dp(32)]));
P7 = (dp(23)- mean([dp(17) dp(18) dp(24) dp(28)]));
P3 = (dp(24)- mean([dp(18) dp(29) dp(23) dp(25)]));
Pz = (dp(25)- mean([dp(19) dp(31) dp(24) dp(26)]));
P4 = (dp(26)- mean([dp(20) dp(32) dp(31) dp(21)]));
P8 = (dp(27)- mean([dp(21) dp(32) dp(31) dp(22)]));
PO9 = (dp(28)- mean([dp(17) dp(23) dp(29) dp(24)]));
O1 = (dp(29)- mean([dp(28) dp(30) dp(24) dp(25)]));
Oz = (dp(30)- mean([dp(29) dp(31) dp(25) dp(24)]));
O2 = (dp(31)- mean([dp(30) dp(32) dp(26) dp(27)]));
PO10 = (dp(32)- mean([dp(31) dp(27) dp(26) dp(22)]));
lap_data = -[Fp1;Fp2;F7; F3; Fz; F4; F8; FC5; FC1; FC2; FC6;
     T7; C3; Cz; C4; T8; TP9; CP5; CP1; CP2; CP6; TP10; P7; P3;
     Pz; P4; P8; PO9; O1; Oz; O2; PO10];
topoplot(lap_data,chanlocs,'colormap','jet');
title('CSD')
% caxis(handles.axes9,'auto');
% colorbar('peer',handles.axes9);
 