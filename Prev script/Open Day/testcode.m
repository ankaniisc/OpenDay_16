
count=10;
totPass=60;
bpower=mean(mean(power(1:10,7:13)));
disp(bpower);
freqs=500;
sampleFreq=44100;
dt=1/sampleFreq;
ti = 0:dt:0.5;
AP = dsp.AudioPlayer('SampleRate',sampleFreq);
while(count < totPass )       
for i=11:50
    alphapower=mean(mean(power(i-4:i,7:13)));
    relalpha=alphapower-bpower;
     
     disp(['displaying relative change in alpha power  ',num2str(relalpha)]);
     
    
    audio(count,:)=sin(2*pi*(freqs+(relalpha*100))*ti);

    step(AP,audio(count,:)');
end
count=count+1;
end