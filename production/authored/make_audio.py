"""Synthesize short original UI/game effects as editable PCM WAV assets."""
import math
from pathlib import Path
import random
import struct
import wave

OUT=Path(__file__).resolve().parents[2]/'game/assets'
RATE=22050
random.seed(924)
effects={'talk':(.13,[620]),'rupee':(.28,[900,1350]),'treasure':(.75,[659,830,988,1318]),'sword':(.16,[180])}
for name,(duration,notes) in effects.items():
    frames=[]
    for i in range(int(duration*RATE)):
        time=i/RATE
        envelope=min(1,time/.008)*max(0,1-time/duration)**1.5
        note=notes[min(len(notes)-1,int(time/duration*len(notes)))]
        tone=math.sin(2*math.pi*note*time)+.18*math.sin(4*math.pi*note*time)
        if name=='sword': tone=.7*random.uniform(-1,1)+.3*math.sin(2*math.pi*(320-180*time/duration)*time)
        frames.append(struct.pack('<h',int(9000*envelope*tone)))
    with wave.open(str(OUT/(name+'.wav')),'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(RATE);wav.writeframes(b''.join(frames))
    print(name,duration)

# Five playable pipe tones, plus original location loops. No recorded game audio.
def write_pcm(name, samples):
    from array import array
    pcm = array('h', (int(max(-1, min(1, value))*26000) for value in samples))
    with wave.open(str(OUT/(name+'.wav')), 'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())

for name,frequency in {'a':440, 'down':493.883, 'right':587.33, 'left':659.255, 'up':880}.items():
    def note_samples():
        for i in range(int(RATE*.55)):
            t=i/RATE
            envelope=min(1,t/.03)*max(0,1-t/.55)**.7
            yield envelope*.32*(math.sin(math.tau*frequency*t)+.12*math.sin(math.tau*frequency*2*t))
    write_pcm('note_'+name,note_samples())

themes = {
    'forest': (96, [64,67,71,69,67,62,64,59], [40,43,38,40], .22),
    'field': (108, [60,64,67,72,71,67,65,62], [36,41,43,36], .24),
    'town': (112, [67,64,62,65,69,67,62,60], [36,45,41,43], .20),
    'ranch': (92, [62,66,69,66,64,69,67,62], [38,43,45,38], .22),
    'hollow': (64, [57,0,60,0,59,0,55,0], [33,32,29,33], .12),
    'boss': (128, [45,0,46,0,52,0,48,0], [33,33,34,32], .14),
}
for name,(bpm,melody,bass,level) in themes.items():
    beat=60/bpm
    duration=beat*32
    def music_samples():
        for i in range(int(duration*RATE)):
            t=i/RATE
            step=int(t/beat)
            local=t%beat
            pitch=melody[step%len(melody)]
            freq=440*2**((pitch-69)/12) if pitch else 0
            env=min(1,local/.012)*math.exp(-local*5/beat)
            lead=(math.sin(math.tau*freq*t)+.15*math.sin(math.tau*freq*2*t))*env*.40 if pitch else 0
            root=440*2**((bass[int(step/8)%4]-69)/12)
            chord=.16*math.sin(math.tau*root*t)+.08*math.sin(math.tau*root*1.5*t)
            pluck=.12*math.sin(math.tau*root*2*t)*math.exp(-local*9/beat)
            edge=min(1,t/.05,(duration-t)/.12)
            yield (lead+chord+pluck)*level*edge
    write_pcm('music_'+name,music_samples())
    print('music_'+name,round(duration,2))
