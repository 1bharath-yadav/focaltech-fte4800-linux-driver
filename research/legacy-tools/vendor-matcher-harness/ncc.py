import numpy as np, itertools
W,H=64,80
d=np.fromfile("/home/archer/projects/zerobook-focaltech-driver/tools/vendor-matcher-harness/frames.bin",dtype=np.uint8).reshape(-1,H,W).astype(float)
lab=[int(x) for x in open("/home/archer/projects/zerobook-focaltech-driver/tools/vendor-matcher-harness/labels.txt").read().split()]
def gk(s):
    r=int(3*s); x=np.arange(-r,r+1); k=np.exp(-x*x/(2*s*s)); return k/k.sum()
def gblur(f,s):
    k=gk(s); f=np.apply_along_axis(lambda m:np.convolve(np.pad(m,len(k)//2,mode='reflect'),k,'valid'),0,f)
    return np.apply_along_axis(lambda m:np.convolve(np.pad(m,len(k)//2,mode='reflect'),k,'valid'),1,f)
def prep(f):
    f=f-gblur(f,6); s=np.sqrt(gblur(f*f,6))+1e-6; return f/s
P=[prep(f) for f in d]
SH=(2*H,2*W)
def fc(x,y):
    return np.fft.irfft2(np.fft.rfft2(x,SH)*np.fft.rfft2(y[::-1,::-1],SH),SH)[:2*H-1,:2*W-1]
ones=np.ones((H,W)); n_map=fc(ones,ones)
def best_ncc(a,b,minfrac):
    sA=fc(a,ones); sB=fc(ones,b); sAB=fc(a,b); sAA=fc(a*a,ones); sBB=fc(ones,b*b)
    n=np.maximum(n_map,1)
    num=sAB-sA*sB/n; den=np.sqrt(np.maximum(sAA-sA**2/n,1e-9)*np.maximum(sBB-sB**2/n,1e-9))
    ncc=num/den; ncc[n_map<minfrac*H*W]=-1
    k=np.unravel_index(np.argmax(ncc),ncc.shape); return ncc[k], n_map[k]/(H*W)
def auc(g,i):
    g=np.array(g);i=np.array(i); return np.mean(g[:,None]>i[None,:])+0.5*np.mean(g[:,None]==i[None,:])
if __name__=="__main__":
    for minfrac in (0.2,0.4,0.5,0.66,0.8):
        gen=[];imp=[]
        for i,j in itertools.combinations(range(len(d)),2):
            s,o=best_ncc(P[i],P[j],minfrac); (gen if lab[i]==lab[j] else imp).append(s)
        gen=np.array(gen);imp=np.array(imp)
        out=[]
        for frr in (0.1,0.3,0.5):
            thr=np.quantile(gen,frr); out.append(f"FRR{int(frr*100)}%:thr {thr:.2f} FAR {np.mean(imp>=thr)*100:4.1f}%")
        print(f"min ovl {int(minfrac*100):2d}%: gen med {np.median(gen):.2f} p10 {np.quantile(gen,.1):.2f} | imp med {np.median(imp):.2f} p95 {np.quantile(imp,.95):.2f} max {imp.max():.2f} | AUC {auc(gen,imp):.3f} | "+"; ".join(out),flush=True)
    for minfrac in (0.5,0.66):
        c=0
        for j in range(15,25):
            c+= max(best_ncc(P[i],P[j],minfrac)[0] for i in range(15))>0.6
        print(f"held-out A frames with enrolled partner >= {int(minfrac*100)}% overlap & NCC>0.6: {c}/10")
