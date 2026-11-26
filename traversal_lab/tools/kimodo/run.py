import json, sys, time, subprocess, os
VER="17111248e89aa145d768cc1e5f7baae228f69d854b996b860becfee287379545"
def api(method, url, body=None):
    cmd=['curl','-sS','-m','120','-X',method,url,'-H','Authorization: Bearer dummy','-H','Content-Type: application/json']
    if body is not None: cmd+=['-d',json.dumps(body)]
    return json.loads(subprocess.run(cmd,capture_output=True,text=True).stdout)
def run(name, inp):
    os.makedirs(name, exist_ok=True)
    p=api('POST','https://api.replicate.com/v1/predictions',{'version':VER,'input':inp})
    tries=0
    while 'id' not in p and p.get('status')==429 and tries<8:
        time.sleep(12); tries+=1; p=api('POST','https://api.replicate.com/v1/predictions',{'version':VER,'input':inp})
    if 'id' not in p: print('ERR',p); return
    while p['status'] in ('starting','processing'):
        time.sleep(5); p=api('GET','https://api.replicate.com/v1/predictions/'+p['id'])
    json.dump(p,open(name+'/prediction.json','w'),indent=1)
    print(name,p['status'],p.get('error'),(p.get('metrics') or {}).get('predict_time'))
    pass
    for u in p.get('output') or []:
        f=name+'/'+u.split('/')[-1]; subprocess.run(['curl','-sS','-m','300','-L','-o',f,u]); print(' ',f,os.path.getsize(f))
if __name__=='__main__':
    run(sys.argv[1], json.loads(sys.argv[2]))
