/* SPDX-License-Identifier: LGPL-2.1-or-later */
#include "vendor-engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static uint16_t u16(const unsigned char*p){return p[0]|((uint16_t)p[1]<<8);}
static uint32_t u32(const unsigned char*p){return p[0]|((uint32_t)p[1]<<8)|((uint32_t)p[2]<<16)|((uint32_t)p[3]<<24);}

static int bmp(const char*path,uint8_t**out,int*w,int*h){
 FILE*f=fopen(path,"rb"); if(!f)return -1; unsigned char hd[54];
 if(fread(hd,1,54,f)!=54||hd[0]!='B'||hd[1]!='M'){fclose(f);return -2;}
 uint32_t off=u32(hd+10),dib=u32(hd+14); int32_t sw=(int32_t)u32(hd+18),sh=(int32_t)u32(hd+22);
 uint16_t bpp=u16(hd+28),cmp=u16(hd+30); if(sw<=0||sh==0||dib<40||cmp||bpp!=8){fclose(f);return -3;}
 int dh=sh<0?-sh:sh; size_t row=((size_t)sw+3)&~3u; uint8_t*img=malloc((size_t)sw*dh),*rb=malloc(row);
 if(!img||!rb){fclose(f);free(img);free(rb);return -4;} if(fseek(f,off,SEEK_SET)){fclose(f);free(img);free(rb);return -5;}
 for(int y=0;y<dh;y++){if(fread(rb,1,row,f)!=row){free(img);free(rb);fclose(f);return -6;}
  int dy=sh>0?dh-1-y:y; for(int x=0;x<sw;x++)img[dy*sw+x]=rb[x];
 } fclose(f);free(rb);*out=img;*w=sw;*h=dh;return 0;
}
int main(int argc,char**argv){
 if(argc<3){fprintf(stderr,"usage: %s DLL frame.bmp [frame.bmp...]\n",argv[0]);return 2;}
 int rc=ft_engine_open(argv[1]); printf("open=%d\n",rc); if(rc)return 10;
 int w,h;ft_engine_geometry(&w,&h);printf("geometry=%dx%d\n",w,h);ft_engine_enroll_begin();
 for(int i=2;i<argc;i++){uint8_t*img=0;int sw=0,sh=0;if(bmp(argv[i],&img,&sw,&sh)){printf("badbmp=%s\n",argv[i]);continue;}
  uint32_t ar=ft_engine_accept(img,sw,sh,4);printf("enroll[%d] hr=0x%08x\n",i-1,ar);
  if(ar==0){int ur=ft_engine_enroll_update();printf("  update=%d\n",ur);if(ur==0){free(img);break;}}
  free(img);
 }
 uint8_t*t=0;size_t n=0;rc=ft_engine_enroll_commit(&t,&n);printf("commit=%d template=%zu\n",rc,n);
 if(rc==0){FILE*f=fopen("/tmp/fte4800-vendor-template.bin","wb");if(f){fwrite(t,1,n,f);fclose(f);}}
 for(int i=2;i<argc;i++){uint8_t*img=0;int sw=0,sh=0;if(bmp(argv[i],&img,&sw,&sh))continue;
  uint32_t ar=ft_engine_accept(img,sw,sh,1);printf("verify[%d] hr=0x%08x",i-1,ar);if(ar==0&&rc==0)printf(" match=%d",ft_engine_verify(t,n));puts("");free(img);}
 free(t);return rc?20:0;
}