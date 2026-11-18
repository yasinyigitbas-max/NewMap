from plan import *
U,V=np.meshgrid(np.arange(-1300,1400,4.0),np.arange(-1700,800,4.0))
F=field(U,V)
gv,gu=np.gradient(F,4.0); G=np.hypot(gu,gv)
print('max grade %.1f%%'%(G.max()*100))
for n,c,r,hh,_ in HILLS:
  sel=(((U-c[0])/r[0])**2+((V-c[1])/r[1])**2)<1.3
  i=np.argmax(np.where(sel,G,0)); print(n,'max grade %.1f%% at u %.0f v %.0f peak %.1f'%(G.flat[i]*100,U.flat[i],V.flat[i],F[sel].max()))
s=SAMPLES[0]; sel=(U>=-56)&(U<=150)&(V>=-100)&(V<=100)
print('pilot mismatch max %.2f m'%np.abs(F[sel]-5.9*ss(40,150,U[sel])).max())
for s in SAMPLES[1:]:
  sel=dist_rect(s,U,V)<=BUF0
  print(s[0],'raise inside apron %.2f'%F[sel].max())
print('share of area over 6%%: %.1f%%'%(100*(G>0.06).mean()))
