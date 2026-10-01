"""Deterministic authored limestone maps: limestone grain, coursed wall and floor.
No photographic textures or recovered game images. Run python3 this_file.py.
"""
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
OUT=Path(__file__).resolve().parents[2]/'game/assets/temple';OUT.mkdir(exist_ok=True)
N=1024;Y,X=np.mgrid[:N,:N];rng=np.random.default_rng(240930)
def smooth_noise(size,blur):
 a=rng.uniform(0,255,(size,size)).astype('uint8');return np.asarray(Image.fromarray(a).resize((N,N),Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(blur)),dtype=float)/255-.5
grain=smooth_noise(128,.5);cloud=smooth_noise(12,8);vein=np.sin(X*.017+Y*.009+cloud*1.4)*.008
for kind in ['limestone','wall','floor']:
 height=.46+grain*.11+cloud*.05
 tone=.025*grain+.048*cloud+vein
 joints=np.zeros((N,N),float)
 variation=np.zeros((N,N))
 if kind!='limestone':
  rows=4 if kind=='floor' else 6
  rh=N/rows;cw=N/(4 if kind=='floor' else 3)
  row=np.floor(Y/rh);sx=X+(row%2)*cw*.5
  dx=np.minimum(sx%cw,cw-sx%cw);dy=np.minimum(Y%rh,rh-Y%rh)
  distance=np.minimum(dx,dy)
  joints=np.clip((2.2-distance)/2.2,0,1)
  # Rounded stone arris catches light over a narrow shoulder, not a broad crack.
  height-=np.clip((5-distance)/5,0,1)*.18
  palette=rng.uniform(-.035,.035,(rows,6));variation=palette[row.astype(int),np.floor(sx/cw).astype(int)]
 pores=rng.random((N,N))>.997
 height-=pores*.035
 color=np.dstack([np.clip(c+tone+variation-joints*.14,0,1) for c in ((.59,.575,.53) if kind=='floor' else (.68,.65,.585))])
 dy,dx=np.gradient(height);normal=np.dstack((-dx*2,-dy*2,np.ones_like(dx)));normal/=np.linalg.norm(normal,axis=2,keepdims=True)
 rough=np.clip(.83+grain*.07+cloud*.03+joints*.08,.71,.97)
 for name,value in [('diff',color),('nor_gl',normal*.5+.5),('rough',rough)]:
  Image.fromarray((value*255).astype('uint8')).save(OUT/(kind+'_'+name+'.png'))
print('Nine authored limestone texture maps saved to',OUT)
