blCount=10;
count=1;
totPass=60;
bpower=mean(mean(power(1:10,7:13)));
disp(bpower);
freqs=500;
sampleFreq=44100;
dt=1/sampleFreq;
ti = 0:dt:0.5;
n=sampleFreq*0.5;
dr=1/0.5;
nr=floor(sampleFreq*dr);
r=sin((linspace(0,pi/2,nr)));
r=[r,ones(1,n-nr*2),fliplr(r)];

AP = dsp.AudioPlayer('SampleRate',sampleFreq);
BLPower=0;
Pc=[];
while(count < totPass )       
% for i=11:50
%     alphapower=mean(mean(power(i-4:i,7:13)));
%     relalpha=alphapower-bpower;
%      
%      disp(['displaying relative change in alpha power  ',num2str(relalpha)]);
     
    
%     audio(count,:)=sin(2*pi*(freqs+(relalpha*100))*ti);
    if (blCount == 0)
            BLPower = mean(mean(power(1:count,8:15)));
    end
    
    if (blCount>0)
        PowerChange = (mean(mean(power(count,8:15))));
    else
        PowerChange = (mean(mean(power(count,8:15)))-BLPower);
    end
%     sig=sin(2*pi*(freqs+exp((45/100)*1.2348*(PowerChange)))*ti);
    audio(count,:)=(sin(2*pi*(freqs+exp((45/100)*1.2348*(PowerChange)))*ti)).*r;
    
    step(AP,audio(count,:)');

count=count+1;
blCount=blCount-1;
disp(count);
disp(PowerChange);
Pc = [Pc PowerChange];
end