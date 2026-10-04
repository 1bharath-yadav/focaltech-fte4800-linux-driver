/* SPDX-License-Identifier: LGPL-2.1-or-later */
// loader.c — native in-process loader for ftWbioEngineAdapter.dll, NO WINE.
// Maps the PE, sets up a fake x64 TEB in %gs, runs static-CRT DllMain, then
// calls WbioQueryEngineInterface + Attach + AcceptSampleData on a real print.
//
// Build: gcc -O0 -g -o loader loader.c
// x86-64 Linux: glibc TLS uses %fs, so %gs is free for the Windows TEB.

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <asm/prctl.h>
#include <pthread.h>

typedef uint8_t u8; typedef uint16_t u16; typedef uint32_t u32; typedef uint64_t u64;
#define MS __attribute__((ms_abi))
#define DLL_PROCESS_ATTACH 1

static u8 *g_image;          // mapped image base
static u64 g_imagebase;      // preferred base 0x180000000
static const char *g_dllpath;

// ---------- tiny PE structures (only fields we use) ----------
#pragma pack(push,1)
typedef struct { u16 e_magic; u8 pad[58]; u32 e_lfanew; } DOS;
typedef struct {
  u32 Signature; u16 Machine, NumSecs; u32 TimeStamp, PtrSym, NumSym; u16 OptSize, Chars;
} FILEHDR;
typedef struct { u8 Name[8]; u32 VSize, VAddr, RawSize, RawPtr; u32 pad[3]; u16 pad2[2]; u32 Chars; } SEC;
#pragma pack(pop)

static u8 *g_file; static long g_filelen;
static u32 f32(u64 o){ return *(u32*)(g_file+o); }
static u64 f64(u64 o){ return *(u64*)(g_file+o); }
static u16 f16(u64 o){ return *(u16*)(g_file+o); }

// ---------- fake TEB / gs ----------
static u8 g_teb[0x2000];
static u8 g_peb[0x1000];
static void *g_tls_array[64];
static u8  g_tls_block[0x2000];

static int set_gs(void *base){ return syscall(SYS_arch_prctl, ARCH_SET_GS, base); }

/* The vendor CRT uses the Windows TEB stack bounds from %gs:+0x08/+0x10
 * for __chkstk probing. Those bounds must describe the *current Linux thread*
 * stack, especially when the engine is called from a GLib worker thread.
 * Keeping the old dummy bounds causes the vendor's stack probe to fault at
 * 0x1800493f8 before VerifyFeatureSet can execute. */
static int arm_teb_for_current_thread(void)
{
  pthread_attr_t attr;
  void *stack_base = NULL;
  size_t stack_size = 0;
  size_t guard_size = 0;

  if (pthread_getattr_np(pthread_self(), &attr) == 0)
    {
      (void) pthread_attr_getstack(&attr, &stack_base, &stack_size);
      (void) pthread_attr_getguardsize(&attr, &guard_size);
      pthread_attr_destroy(&attr);

      if (stack_base && stack_size)
        {
          uintptr_t low = (uintptr_t) stack_base + guard_size;
          uintptr_t high = (uintptr_t) stack_base + stack_size;
          *(u64*)(g_teb + 0x08) = high; /* NtTib.StackBase */
          *(u64*)(g_teb + 0x10) = low;  /* NtTib.StackLimit */
        }
    }

  return set_gs(g_teb);
}

// ---------- import shim table ----------
typedef struct { const char *name; void *fn; } Shim;
static Shim shims[128]; static int nshims;
static void reg(const char*n, void*f){ if(nshims>=(int)(sizeof shims/sizeof*shims)){fprintf(stderr,"ft_engine: shim table full (%d) — raise shims[]\n",nshims);abort();} shims[nshims].name=n; shims[nshims].fn=f; nshims++; }
static void* find_shim(const char*n){ for(int i=0;i<nshims;i++) if(!strcmp(shims[i].name,n)) return shims[i].fn; return 0; }

// ================= SHIMS (all MS ABI) =================

// ---------- BCrypt SHA-256 shim (real hashing, no crypto bypass) ----------
#define STATUS_SUCCESS 0u
#define STATUS_INVALID_PARAMETER 0xC000000Du
#define STATUS_BUFFER_TOO_SMALL 0xC0000023u
#define ERROR_FILE_NOT_FOUND 2u

typedef struct {
  u32 h[8];
  u64 bits;
  u8 buf[64];
  u32 used;
} Sha256Ctx;

static u32 rotr32(u32 x,u32 n){ return (x>>n)|(x<<(32-n)); }
static u32 ch32(u32 x,u32 y,u32 z){ return (x&y)^(~x&z); }
static u32 maj32(u32 x,u32 y,u32 z){ return (x&y)^(x&z)^(y&z); }
static u32 s0_256(u32 x){ return rotr32(x,2)^rotr32(x,13)^rotr32(x,22); }
static u32 s1_256(u32 x){ return rotr32(x,6)^rotr32(x,11)^rotr32(x,25); }
static u32 g0_256(u32 x){ return rotr32(x,7)^rotr32(x,18)^(x>>3); }
static u32 g1_256(u32 x){ return rotr32(x,17)^rotr32(x,19)^(x>>10); }

static const u32 sha256_k[64]={
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static void sha256_init(Sha256Ctx*c){
  static const u32 iv[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
  memcpy(c->h,iv,sizeof iv); c->bits=0; c->used=0;
}
static void sha256_block(Sha256Ctx*c,const u8*b){
  u32 w[64],a,bb,cc,d,e,f,g,h1;
  for(int i=0;i<16;i++) w[i]=((u32)b[i*4]<<24)|((u32)b[i*4+1]<<16)|((u32)b[i*4+2]<<8)|b[i*4+3];
  for(int i=16;i<64;i++) w[i]=g1_256(w[i-2])+w[i-7]+g0_256(w[i-15])+w[i-16];
  a=c->h[0]; bb=c->h[1]; cc=c->h[2]; d=c->h[3]; e=c->h[4]; f=c->h[5]; g=c->h[6]; h1=c->h[7];
  for(int i=0;i<64;i++){
    u32 t1=h1+s1_256(e)+ch32(e,f,g)+sha256_k[i]+w[i];
    u32 t2=s0_256(a)+maj32(a,bb,cc);
    h1=g; g=f; f=e; e=d+t1; d=cc; cc=bb; bb=a; a=t1+t2;
  }
  c->h[0]+=a; c->h[1]+=bb; c->h[2]+=cc; c->h[3]+=d; c->h[4]+=e; c->h[5]+=f; c->h[6]+=g; c->h[7]+=h1;
}
static void sha256_update(Sha256Ctx*c,const u8*p,u32 n){
  c->bits += (u64)n*8;
  while(n){
    u32 take=64-c->used; if(take>n) take=n;
    memcpy(c->buf+c->used,p,take); c->used+=take; p+=take; n-=take;
    if(c->used==64){ sha256_block(c,c->buf); c->used=0; }
  }
}
static void sha256_final(Sha256Ctx*c,u8*out){
  u32 used=c->used; c->buf[used++]=0x80;
  if(used>56){ memset(c->buf+used,0,64-used); sha256_block(c,c->buf); used=0; }
  memset(c->buf+used,0,56-used);
  for(int i=0;i<8;i++) c->buf[56+i]=(u8)(c->bits>>(56-8*i));
  sha256_block(c,c->buf);
  for(int i=0;i<8;i++){ out[4*i]=(u8)(c->h[i]>>24); out[4*i+1]=(u8)(c->h[i]>>16); out[4*i+2]=(u8)(c->h[i]>>8); out[4*i+3]=(u8)c->h[i]; }
}
static int w16eq(const u16*s,const char*ascii){
  int i=0; for(;ascii[i];i++) if(s[i]!=(u8)ascii[i]) return 0; return s[i]==0;
}
static int g_sha_algorithm;
static u32 MS sh_BCryptOpenAlgorithmProvider(void**ph,const u16*algid,const u16*impl,u32 fl){
  if(!ph || !algid || !w16eq(algid,"SHA256")) return STATUS_INVALID_PARAMETER;
  *ph=&g_sha_algorithm; return STATUS_SUCCESS;
}
static u32 MS sh_BCryptCloseAlgorithmProvider(void*h,u32 fl){ return h==&g_sha_algorithm?STATUS_SUCCESS:STATUS_INVALID_PARAMETER; }
static u32 MS sh_BCryptCreateHash(void*h,void**ph,u8*ho,u32 cho,u8*sec,u32 csec,u32 fl){
  if(h!=&g_sha_algorithm || !ph) return STATUS_INVALID_PARAMETER;
  Sha256Ctx*c=malloc(sizeof(*c)); if(!c) return 0xC0000017u; sha256_init(c); *ph=c; return STATUS_SUCCESS;
}
static u32 MS sh_BCryptHashData(void*h,u8*in,u32 cb,u32 fl){
  if(!h || (!in && cb)) return STATUS_INVALID_PARAMETER;
  sha256_update((Sha256Ctx*)h,in,cb);
  return STATUS_SUCCESS;
}
static u32 MS sh_BCryptDestroyHash(void*h){ if(!h) return STATUS_INVALID_PARAMETER; free(h); return STATUS_SUCCESS; }
static u32 MS sh_BCryptFinishHash(void*h,u8*out,u32 cb,u32 fl){
  if(!h || !out || cb<32) return cb<32?STATUS_BUFFER_TOO_SMALL:STATUS_INVALID_PARAMETER;
  Sha256Ctx c=*(Sha256Ctx*)h; sha256_final(&c,out); return STATUS_SUCCESS;
}
static u32 MS sh_BCryptGetProperty(void*h,const u16*prop,u8*out,u32 cb,u32*res,u32 fl){
  if(!prop || !res) return STATUS_INVALID_PARAMETER;
  u32 v=0;
  if(w16eq(prop,"HashDigestLength")) v=32;
  else if(w16eq(prop,"ObjectLength")) v=sizeof(Sha256Ctx);
  else if(w16eq(prop,"BlockLength")) v=64;
  else return 0xC0000059u;
  *res=4; if(!out || cb<4) return STATUS_BUFFER_TOO_SMALL; *(u32*)out=v; return STATUS_SUCCESS;
}

// ---------- ADVAPI32 registry shim: report absent vendor configuration ----------
static u32 MS sh_RegOpenKeyExA(void*h,const char*sub,u32 opt,u32 access,void*out){ if(out)*(u64*)out=0; return ERROR_FILE_NOT_FOUND; }
static u32 MS sh_RegQueryValueExA(void*h,const char*name,u32*r0,u32*r1,u8*data,u32*pcb){ return ERROR_FILE_NOT_FOUND; }
static u32 MS sh_RegCloseKey(void*h){ return 0; }

static u32 g_lasterr=0;
static void MS sh_SetLastError(u32 e){ g_lasterr=e; }
static u32  MS sh_GetLastError(void){ return g_lasterr; }

static void* MS sh_GetProcessHeap(void){ return (void*)0x100; }
static void* MS sh_HeapAlloc(void*h,u32 flags,u64 size){ void*p=malloc(size?size:1); if(p&&(flags&8)) memset(p,0,size); return p; }
static int   MS sh_HeapFree(void*h,u32 f,void*p){ free(p); return 1; }
static void* MS sh_HeapReAlloc(void*h,u32 f,void*p,u64 s){ return realloc(p,s); }
static u64   MS sh_HeapSize(void*h,u32 f,void*p){ return 0; }
static int   MS sh_HeapValidate(void*h,u32 f,void*p){ return 1; }
static int   MS sh_HeapQueryInformation(void*h,int c,void*b,u64 l,u64*r){ return 0; }

static void MS sh_InitCS(void*p){ }
static u32  MS sh_InitCSSpin(void*p,u32 s){ return 1; }
static u32  MS sh_InitCSEx(void*p,u32 s,u32 flags){ return 1; }
static void MS sh_InitConditionVariable(void*p){ memset(p,0,8); }
static int   MS sh_WakeAllConditionVariable(void*p){ return 1; }
static int   MS sh_SleepConditionVariableCS(void*cv,void*cs,u32 ms,u32 flags){ return 1; }
static void MS sh_EnterCS(void*p){ }
static void MS sh_LeaveCS(void*p){ }
static void MS sh_DeleteCS(void*p){ }
static void MS sh_InitSList(void*p){ memset(p,0,16); }
static void* MS sh_FlushSList(void*p){ return 0; }

// TLS
static u32 g_tls_next=1; static void* g_tls_vals[1088];
static u32 g_fls_next=1; static void* g_fls_vals[1088];
static u32  MS sh_FlsAlloc(void(*cb)(void*)){ return g_fls_next++; }
static int  MS sh_FlsFree(u32 i){ return 1; }
static void* MS sh_FlsGetValue(u32 i){ g_lasterr=0; return i<1088?g_fls_vals[i]:0; }
static int  MS sh_FlsSetValue(u32 i,void*v){ if(i<1088)g_fls_vals[i]=v; return 1; }
static u32  MS sh_TlsAlloc(void){ return g_tls_next++; }
static int  MS sh_TlsFree(u32 i){ return 1; }
static void* MS sh_TlsGetValue(u32 i){ g_lasterr=0; return i<1088?g_tls_vals[i]:0; }
static int  MS sh_TlsSetValue(u32 i,void*v){ if(i<1088) g_tls_vals[i]=v; return 1; }

// process/thread/module
static void* MS sh_GetCurrentProcess(void){ return (void*)-1; }
static u32  MS sh_GetCurrentProcessId(void){ return 1234; }
static u32  MS sh_GetCurrentThreadId(void){ return 5678; }
static void* MS sh_GetModuleHandleW(void*n){ return (void*)g_image; }
static void* MS sh_GetModuleHandleA(void*n){ return (void*)g_image; }
static int  MS sh_GetModuleHandleExW(u32 f,void*n,void**h){ if(h)*h=(void*)g_image; return 1; }
static u32  MS sh_GetModuleFileNameA(void*m,char*b,u32 n){ strncpy(b,g_dllpath,n); return strlen(g_dllpath); }
static u32  MS sh_GetModuleFileNameW(void*m,u16*b,u32 n){ u32 i=0; for(;g_dllpath[i]&&i<n-1;i++) b[i]=g_dllpath[i]; b[i]=0; return i; }
static void* MS sh_LoadLibraryExW(void*n,void*h,u32 f){ return (void*)0x1000; }
static int  MS sh_FreeLibrary(void*h){ return 1; }
static void* MS sh_GetProcAddress(void*h,const char*n){ if((u64)n>>16==0) return 0; /*by ordinal*/ return find_shim(n); }

// console/file → route engine logs to stderr so we SEE its [Engine] output
static void* MS sh_GetStdHandle(u32 n){ return (void*)(u64)(n?n:1); }
static int  MS sh_SetStdHandle(u32 n,void*h){ return 1; }
static u32  MS sh_GetFileType(void*h){ return 2; /*CHAR*/ }
static int  MS sh_GetConsoleMode(void*h,u32*m){ if(m)*m=0; return 1; }
static u32  MS sh_GetConsoleCP(void){ return 437; }
static int  MS sh_WriteFile(void*h,const void*b,u32 n,u32*wr,void*o){ fwrite(b,1,n,stderr); if(wr)*wr=n; return 1; }
static int  MS sh_WriteConsoleW(void*h,const u16*b,u32 n,u32*wr,void*r){ for(u32 i=0;i<n;i++) fputc(b[i]&0xff,stderr); if(wr)*wr=n; return 1; }
static void MS sh_OutputDebugStringA(const char*s){ fprintf(stderr,"%s",s?s:""); }
static void MS sh_OutputDebugStringW(const u16*s){ if(s)for(;*s;s++) fputc(*s&0xff,stderr); }
static int  MS sh_FlushFileBuffers(void*h){ return 1; }
static void* MS sh_CreateFileW(void*n,u32 a,u32 s,void*sa,u32 c,u32 fl,void*t){ g_lasterr=2; return (void*)-1; } // config absent → graceful
static int  MS sh_SetFilePointerEx(void*h,long long d,void*np,u32 m){ return 0; }
static int  MS sh_CloseHandle(void*h){ return 1; }
static void* MS sh_FindFirstFileExA(void*n,int i,void*d,int o,void*s,u32 f){ return (void*)-1; }
static int  MS sh_FindNextFileA(void*h,void*d){ return 0; }
static void* MS sh_FindFirstFileExW(void*n,int i,void*d,int o,void*s,u32 f){ return (void*)-1; }
static int  MS sh_FindNextFileW(void*h,void*d){ return 0; }
static int  MS sh_CSpecificHandler(void*a,void*b,void*c,void*d){ return 0; }
static int  MS sh_FindClose(void*h){ return 1; }
static u32  MS sh_GetSystemDirectoryA(char*b,u32 n){ strncpy(b,"C:\\Windows\\System32",n); return 19; }

// sync / events → the engine's global lock
static void* MS sh_CreateEventW(void*sa,int man,int init,void*name){ return (void*)0x2000; }
static int  MS sh_SetEvent(void*h){ return 1; }
static int  MS sh_ResetEvent(void*h){ return 1; }
static u32  MS sh_WaitForSingleObject(void*h,u32 ms){ return 0; /*WAIT_OBJECT_0*/ }
static u32  MS sh_WaitForSingleObjectEx(void*h,u32 ms,int a){ return 0; }
static void* MS sh_CreateThread(void*sa,u64 st,void*fn,void*arg,u32 fl,u32*id){ if(id)*id=4321; return (void*)0x3000; }
static int  MS sh_DeviceIoControl(void*h,u32 c,void*ib,u32 il,void*ob,u32 ol,u32*ret,void*ov){ return 0; }

// locale / codepage (ucrt init)
static u32  MS sh_GetACP(void){ return 1252; }
static u32  MS sh_GetOEMCP(void){ return 437; }
static int  MS sh_GetCPInfo(u32 cp,void*info){ if(info){ u8*p=info; *(u32*)p=1; p[4]=0; p[5]=0; } return 1; }
static int  MS sh_IsValidCodePage(u32 cp){ return 1; }
static int  MS sh_MultiByteToWideChar(u32 cp,u32 f,const char*mb,int mbc,u16*wc,int wcc){
  if(mbc<0) mbc=strlen(mb)+1;
  if(wcc==0) return mbc;
  int n=mbc<wcc?mbc:wcc;
  for(int i=0;i<n;i++) wc[i]=(u8)mb[i];
  return n; }
static int  MS sh_WideCharToMultiByte(u32 cp,u32 f,const u16*wc,int wcc,char*mb,int mbc,void*d,void*u){
  if(wcc<0){ wcc=0; while(wc[wcc]) wcc++; wcc++; } if(mbc==0) return wcc; int n=wcc<mbc?wcc:mbc; for(int i=0;i<n;i++) mb[i]=(char)wc[i]; return n; }
static int  MS sh_LCMapStringW(u32 l,u32 f,const u16*s,int sc,u16*d,int dc){ if(dc==0) return sc; int n=sc<dc?sc:dc; for(int i=0;i<n;i++) d[i]=s[i]; return n; }
static int  MS sh_GetStringTypeW(u32 t,const u16*s,int c,u16*out){ for(int i=0;i<c;i++) out[i]=0; return 1; }

// misc / version / cpu
static void MS sh_GetSystemInfo(void*p){ memset(p,0,64); u8*b=p; *(u32*)(b+0)=9; *(u32*)(b+4)=4096; }
static void MS sh_GetSystemTimeAsFileTime(u64*ft){ static u64 t=0x01d0000000000000ULL; *ft=(t+=100000); }
static u32  MS sh_GetTickCount(void){ static u32 t=1000; return (t+=5); }
static int  MS sh_QueryPerformanceCounter(u64*c){ static u64 t=0; *c=(t+=1000); return 1; }
static int  MS sh_IsDebuggerPresent(void){ return 0; }
static int  MS sh_IsProcessorFeaturePresent(u32 f){ return 1; }
static void* MS sh_EncodePointer(void*p){ return p; }
static void* MS sh_DecodePointer(void*p){ return p; }
static u64  MS sh_VerSetConditionMask(u64 m,u32 t,u8 c){ return m; }
static int  MS sh_VerifyVersionInfoA(void*vi,u32 tm,u64 cm){ return 1; }
static char g_cmd[]="loader"; static u16 g_cmdw[]={'l','o','a','d','e','r',0};
static char* MS sh_GetCommandLineA(void){ return g_cmd; }
static u16*  MS sh_GetCommandLineW(void){ return g_cmdw; }
static void MS sh_GetStartupInfoW(void*si){ memset(si,0,104); *(u32*)si=104; }
static u16 g_env[2]={0,0};
static u16* MS sh_GetEnvironmentStringsW(void){ return g_env; }
static int  MS sh_FreeEnvironmentStringsW(void*p){ return 1; }

// exception/unwind (only hit if the engine throws — hope not)
static void MS sh_RtlCaptureContext(void*ctx){ memset(ctx,0,1232); }
static void* MS sh_RtlLookupFunctionEntry(u64 pc,u64*base,void*hist){ if(base)*base=g_imagebase; return 0; }
static void* MS sh_RtlVirtualUnwind(u32 t,u64 b,u64 pc,void*fe,void*ctx,void**hd,u64*est,void*ctxp){ return 0; }
static void MS sh_RtlUnwindEx(void*a,void*b,void*c,void*d,void*e,void*f){ }
static void* MS sh_RtlPcToFileHeader(void*pc,void**base){ if(base)*base=(void*)g_image; return (void*)g_image; }
static void* MS sh_SetUnhandledExceptionFilter(void*f){ return 0; }
static u32  MS sh_UnhandledExceptionFilter(void*p){ return 1; }
static void MS sh_RaiseException(u32 code,u32 fl,u32 n,void*a){ fprintf(stderr,"[!] RaiseException code=%#x\n",code); }
static void MS sh_TerminateProcess(void*h,u32 c){ fprintf(stderr,"[!] TerminateProcess(%u)\n",c); }
static void MS sh_ExitProcess(u32 c){ fprintf(stderr,"[!] ExitProcess(%u)\n",c); }

static void register_shims(void){
#define R(n) reg(#n, (void*)sh_##n)
  R(BCryptOpenAlgorithmProvider);R(BCryptCreateHash);R(BCryptHashData);R(BCryptDestroyHash);R(BCryptCloseAlgorithmProvider);R(BCryptFinishHash);R(BCryptGetProperty);
  R(RegQueryValueExA);R(RegOpenKeyExA);R(RegCloseKey);
  R(SetLastError);R(GetLastError);R(GetProcessHeap);R(HeapAlloc);R(HeapFree);R(HeapReAlloc);
  R(HeapSize);R(HeapValidate);R(HeapQueryInformation);
  reg("InitializeCriticalSection",sh_InitCS);reg("InitializeCriticalSectionAndSpinCount",sh_InitCSSpin);reg("InitializeCriticalSectionEx",sh_InitCSEx);
  reg("InitializeConditionVariable",sh_InitConditionVariable);reg("WakeAllConditionVariable",sh_WakeAllConditionVariable);reg("SleepConditionVariableCS",sh_SleepConditionVariableCS);
  reg("EnterCriticalSection",sh_EnterCS);reg("LeaveCriticalSection",sh_LeaveCS);reg("DeleteCriticalSection",sh_DeleteCS);
  reg("InitializeSListHead",sh_InitSList);reg("InterlockedFlushSList",sh_FlushSList);
  R(TlsAlloc);R(TlsFree);R(TlsGetValue);R(TlsSetValue);
  R(FlsAlloc);R(FlsFree);R(FlsGetValue);R(FlsSetValue);
  R(GetCurrentProcess);R(GetCurrentProcessId);R(GetCurrentThreadId);
  R(GetModuleHandleW);R(GetModuleHandleA);R(GetModuleHandleExW);R(GetModuleFileNameA);R(GetModuleFileNameW);
  R(LoadLibraryExW);R(FreeLibrary);R(GetProcAddress);
  R(GetStdHandle);R(SetStdHandle);R(GetFileType);R(GetConsoleMode);R(GetConsoleCP);
  R(WriteFile);R(WriteConsoleW);R(OutputDebugStringA);R(OutputDebugStringW);R(FlushFileBuffers);
  R(CreateFileW);R(SetFilePointerEx);R(CloseHandle);R(FindFirstFileExA);R(FindNextFileA);R(FindFirstFileExW);R(FindNextFileW);R(FindClose);R(GetSystemDirectoryA);
  R(CreateEventW);R(SetEvent);R(ResetEvent);R(WaitForSingleObject);R(WaitForSingleObjectEx);R(CreateThread);R(DeviceIoControl);
  R(GetACP);R(GetOEMCP);R(GetCPInfo);R(IsValidCodePage);R(MultiByteToWideChar);R(WideCharToMultiByte);R(LCMapStringW);R(GetStringTypeW);
  R(GetSystemInfo);R(GetSystemTimeAsFileTime);R(GetTickCount);R(QueryPerformanceCounter);R(IsDebuggerPresent);R(IsProcessorFeaturePresent);
  R(EncodePointer);R(DecodePointer);R(VerSetConditionMask);R(VerifyVersionInfoA);
  R(GetCommandLineA);R(GetCommandLineW);R(GetStartupInfoW);R(GetEnvironmentStringsW);R(FreeEnvironmentStringsW);
  R(RtlCaptureContext);R(RtlLookupFunctionEntry);R(RtlVirtualUnwind);R(RtlUnwindEx);R(RtlPcToFileHeader);reg("__C_specific_handler",sh_CSpecificHandler);
  R(SetUnhandledExceptionFilter);R(UnhandledExceptionFilter);R(RaiseException);R(TerminateProcess);R(ExitProcess);
#undef R
}

// ================= PE LOADER =================
static int load_pe(void){
  int fd=open(g_dllpath,O_RDONLY); if(fd<0){perror("open");return -1;}
  g_filelen=lseek(fd,0,SEEK_END); lseek(fd,0,SEEK_SET);
  g_file=malloc(g_filelen); read(fd,g_file,g_filelen); close(fd);

  u32 e=f32(0x3c);
  g_imagebase=f64(e+24+24);
  u32 sizeofimage=f32(e+24+56);
  u32 entry=f32(e+24+16);
  u16 nsec=f16(e+6);
  u16 optsize=f16(e+20);
  u64 sectbl=e+24+optsize;

  u32 hdrsize=f32(e+24+60); // SizeOfHeaders

  /* Prepare the fully-resolved image in a scratch buffer (writable, NOT
   * executable), then map it back from an anonymous FILE (memfd) with per-section
   * protections. This keeps code read+execute and data read+write, so no page is
   * ever writable AND executable at once — which lets the engine run under
   * fprintd's MemoryDenyWriteExecute=yes hardening (no systemd override needed).
   * The DLL loads at its preferred base 0x180000000, so no relocations are
   * required. */
  u8 *img=calloc(1,sizeofimage);
  if(!img){ perror("calloc"); return -1; }
  memcpy(img,g_file,hdrsize);
  for(int i=0;i<nsec;i++){
    u64 s=sectbl+i*40;
    u32 vaddr=f32(s+12), rawsize=f32(s+16), rawptr=f32(s+20);
    memcpy(img+vaddr, g_file+rawptr, rawsize);
  }

  /* resolve kernel32 imports into the IAT within the scratch buffer */
  u32 imprva=f32(e+24+112+8*1);
  for(u64 d=imprva;;d+=20){
    u32 orig=*(u32*)(img+d), namer=*(u32*)(img+d+12), fthunk=*(u32*)(img+d+16);
    if(namer==0) break;
    u64 rt=orig?orig:fthunk;
    for(int j=0;;j++){
      u64 ent=*(u64*)(img+rt+j*8);
      if(!ent) break;
      u64 *slot=(u64*)(img+fthunk+j*8);
      if(ent>>63){ *slot=0; continue; } // by ordinal: none needed
      const char*fn=(char*)(img+(ent&0x7fffffff)+2);
      void*sh=find_shim(fn);
      if(!sh) fprintf(stderr,"[loader] MISSING shim: %s\n",fn);
      *slot=(u64)sh;
    }
  }

  /* write the prepared image to an anonymous in-memory file */
  int mfd=memfd_create("ftengine",MFD_CLOEXEC);
  if(mfd<0){ perror("memfd_create"); free(img); return -1; }
  ssize_t wr=write(mfd,img,sizeofimage);
  free(img);
  if(wr!=(ssize_t)sizeofimage){ perror("write memfd"); close(mfd); return -1; }

  /* reserve the preferred base, then map each section from the file (W^X-safe) */
  void *m=mmap((void*)g_imagebase,sizeofimage,PROT_NONE,
               MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0);
  if(m==MAP_FAILED || m!=(void*)g_imagebase){
    fprintf(stderr,"[loader] reserve @%#lx failed (%p)\n",g_imagebase,m); close(mfd); return -1;
  }
  g_image=m;
  u32 hdrmap=(hdrsize+0xfff)&~0xfffu;
  if(mmap(g_image,hdrmap,PROT_READ,MAP_PRIVATE|MAP_FIXED,mfd,0)==MAP_FAILED){
    perror("[loader] map headers"); close(mfd); return -1;
  }
  for(int i=0;i<nsec;i++){
    u64 s=sectbl+i*40;
    u32 vaddr=f32(s+12), vsize=f32(s+8), rawsize=f32(s+16), chars=f32(s+36);
    u32 seglen=(vsize>rawsize?vsize:rawsize); seglen=(seglen+0xfff)&~0xfffu;
    if(vaddr+seglen>sizeofimage) seglen=sizeofimage-vaddr;
    if(!seglen) continue;
    int prot=PROT_READ;
    if(chars&0x20000000) prot|=PROT_EXEC;   // IMAGE_SCN_MEM_EXECUTE
    if(chars&0x80000000) prot|=PROT_WRITE;  // IMAGE_SCN_MEM_WRITE
    if(mmap(g_image+vaddr,seglen,prot,MAP_PRIVATE|MAP_FIXED,mfd,vaddr)==MAP_FAILED){
      perror("[loader] map section"); close(mfd); return -1;
    }
  }
  close(mfd);
  fprintf(stderr,"[loader] file-backed image at %#lx (no W+X), entry RVA %#x\n",g_imagebase,entry);

  // TLS setup (dir 9): copy template, wire teb->tls array
  u32 tlsrva=f32(e+24+112+8*9);
  if(tlsrva){
    u64 start=*(u64*)(g_image+tlsrva);
    u64 end=*(u64*)(g_image+tlsrva+8);
    u64 idxaddr=*(u64*)(g_image+tlsrva+16);
    u64 cbaddr=*(u64*)(g_image+tlsrva+24);
    u64 tlen=end-start;
    memset(g_tls_block,0,sizeof g_tls_block);
    if(tlen) memcpy(g_tls_block,(void*)start,tlen);
    g_tls_array[0]=g_tls_block;
    if(idxaddr) *(u32*)idxaddr=0;
    fprintf(stderr,"[loader] TLS template %lu bytes, callbacks@%#lx\n",tlen,cbaddr);
    // run TLS callbacks
    if(cbaddr){ for(u64*cb=(u64*)cbaddr; *cb; cb++){ void(MS *f)(void*,u32,void*)=(void*)*cb; f((void*)g_imagebase,DLL_PROCESS_ATTACH,0);} }
  }

  // fake TEB in %gs
  memset(g_teb,0,sizeof g_teb); memset(g_peb,0,sizeof g_peb);
  *(u64*)(g_teb+0x30)=(u64)g_teb;            // NtTib.Self
  *(u64*)(g_teb+0x08)=(u64)(g_teb+0x2000);   // StackBase (dummy)
  *(u64*)(g_teb+0x10)=(u64)g_teb;            // StackLimit
  *(u64*)(g_teb+0x58)=(u64)g_tls_array;      // ThreadLocalStoragePointer
  *(u64*)(g_teb+0x60)=(u64)g_peb;            // PEB
  if(arm_teb_for_current_thread()!=0){ perror("arch_prctl SET_GS"); return -1; }
  fprintf(stderr,"[loader] TEB installed in %%gs\n");

  // run entry point (DllMain via CRT startup)
  int(MS *DllMain)(void*,u32,void*)=(void*)(g_image+entry);
  fprintf(stderr,"[loader] calling entry (DllMain) ...\n");
  int r=DllMain((void*)g_imagebase,DLL_PROCESS_ATTACH,0);
  fprintf(stderr,"[loader] DllMain returned %d\n",r);
  return r?0:-2;
}

// find an export by name
static void* get_export(const char*want){
  u32 e=f32(0x3c);
  u32 exprva=f32(e+24+112+8*0);
  u32 nnames=*(u32*)(g_image+exprva+24);
  u32 fns=*(u32*)(g_image+exprva+28);
  u32 names=*(u32*)(g_image+exprva+32);
  u32 ords=*(u32*)(g_image+exprva+36);
  for(u32 i=0;i<nnames;i++){
    u32 nrva=*(u32*)(g_image+names+i*4);
    if(!strcmp((char*)(g_image+nrva),want)){
      u16 ord=*(u16*)(g_image+ords+i*2);
      u32 frva=*(u32*)(g_image+fns+ord*4);
      return g_image+frva;
    }
  }
  return 0;
}

// ================= engine driving (mirrors the Go harness) =================
static u8 pipeline[1024];
static u8 birbuf[262144];

static u8 small[262144];
static void resize(u8*src,int sw,int sh,int dw,int dh){ for(int y=0;y<dh;y++)for(int x=0;x<dw;x++) small[y*dw+x]=src[(y*sh/dh)*sw+(x*sw/dw)]; }
// Prepare the vendor engine's 64x80 frame. Native FTE4800 captures are a direct
// copy; larger inputs are centre-cropped and smaller inputs are resized for the
// standalone harness.
#define FRAME_W 64
#define FRAME_H 80
static void prepare_frame(const u8*src,int sw,int sh){
  if(sw>=FRAME_W && sh>=FRAME_H){
    int ox=(sw-FRAME_W)/2, oy=(sh-FRAME_H)/2;
    for(int y=0;y<FRAME_H;y++) for(int x=0;x<FRAME_W;x++) small[y*FRAME_W+x]=src[(oy+y)*sw+(ox+x)];
  } else {
    resize((u8*)src, sw, sh, FRAME_W, FRAME_H);
  }
}
static int build_bir(u8*pix,int w,int h){
  int total=0x48+0x38+w*h; memset(birbuf,0,total);
  const int HDR=0x18,STD=0x48;
  *(u32*)(birbuf+0)=0x30; *(u32*)(birbuf+4)=HDR;
  *(u32*)(birbuf+8)=0x38+w*h; *(u32*)(birbuf+0xc)=STD;
  *(u16*)(birbuf+HDR+0x28)=0x001B; *(u16*)(birbuf+HDR+0x2a)=0x0401;
  *(u16*)(birbuf+STD+0x1c)=500; *(u16*)(birbuf+STD+0x1e)=500;
  birbuf[STD+0x22]=8; birbuf[STD+0x23]=0;
  *(u16*)(birbuf+STD+0x2c)=w; *(u16*)(birbuf+STD+0x2e)=h;
  memcpy(birbuf+STD+0x38,pix,w*h);
  return total;
}

// ================= STORAGE ADAPTER STUB (pipeline+0x28 vtable) =================
// Vtable: 0x20 header + function slots (standard WINBIO_STORAGE_INTERFACE order).
// Offsets the engine calls (verified by disassembly):
//   +0x68 AddRecord  +0x78 QueryBySubject  +0x90 FirstRecord
//   +0x98 NextRecord +0xa0 GetCurrentRecord
// WINBIO_STORAGE_RECORD fields the engine uses: +0x00 Identity*, +0x20 TemplateBlob,
//   +0x28 TemplateBlobSize.
static u8  g_rec_identity[76];
static u8  g_rec_template[1<<20];   // enrollment template can be ~200KB (up to 18 sub-tpls)
static u64 g_rec_tsize = 0;
static int g_have_record = 0;

static u64 MS st_default(void*a,void*b,void*c,void*d,void*e,void*f){ return 0; }

static u32 MS st_QueryBySubject(void*pipe,void*identity,u8 sub){
  fprintf(stderr,"[storage] QueryBySubject(sub=%u) -> %s\n", sub,
          g_have_record?"S_OK":"NO_RESULTS");
  if(identity) memcpy(g_rec_identity, identity, sizeof g_rec_identity);
  return g_have_record ? 0 : 0x8009801f; // WINBIO_E_DATABASE_NO_RESULTS
}
static u32 MS st_FirstRecord(void*pipe){
  fprintf(stderr,"[storage] FirstRecord -> %s\n", g_have_record?"S_OK":"NO_RESULTS");
  return g_have_record ? 0 : 0x8009801f;
}
static u32 MS st_NextRecord(void*pipe){
  fprintf(stderr,"[storage] NextRecord -> NO_MORE_RECORDS\n");
  return 0x80098020; // single-record store: always end after the first
}
static u32 MS st_GetCurrentRecord(void*pipe,u8*rec){
  fprintf(stderr,"[storage] GetCurrentRecord (tsize=%lu)\n",(unsigned long)g_rec_tsize);
  memset(rec,0,0x40);
  *(u64*)(rec+0x00)=(u64)g_rec_identity;
  *(u64*)(rec+0x20)=(u64)g_rec_template;
  *(u64*)(rec+0x28)=g_rec_tsize;
  return 0;
}
static u32 MS st_AddRecord(void*pipe,u8*rec,u8 sub){
  u64 tp=*(u64*)(rec+0x20), ts=*(u64*)(rec+0x28);
  u64 idp=*(u64*)(rec+0x00);
  fprintf(stderr,"[storage] AddRecord(sub=%u) template=%#lx size=%lu\n",sub,(unsigned long)tp,(unsigned long)ts);
  if(idp) memcpy(g_rec_identity,(void*)idp,sizeof g_rec_identity);
  if(tp && ts && ts<=sizeof g_rec_template){ memcpy(g_rec_template,(void*)tp,ts); g_rec_tsize=ts; g_have_record=1; }
  return 0;
}

static u64 g_storage_vt[0x100/8];
static u64 g_sensor_vt[0x100/8];
static void build_storage_vtable(void){
  for(int i=0;i<0x100/8;i++){ g_storage_vt[i]=(u64)st_default; g_sensor_vt[i]=(u64)st_default; }
  g_storage_vt[0x68/8]=(u64)st_AddRecord;
  g_storage_vt[0x78/8]=(u64)st_QueryBySubject;
  g_storage_vt[0x90/8]=(u64)st_FirstRecord;
  g_storage_vt[0x98/8]=(u64)st_NextRecord;
  g_storage_vt[0xa0/8]=(u64)st_GetCurrentRecord;
}


/* ==================== public API (ft_engine.h) ==================== */
#include "vendor-engine.h"
#define ENG_W 64
#define ENG_H 80
static void *g_iface;

void ft_engine_geometry(int *w,int *h){ if(w)*w=ENG_W; if(h)*h=ENG_H; }

static int g_loaded = 0;
int ft_engine_open(const char *dll_path){
  /* Re-arm the %gs TEB on re-open: arch_prctl is per-thread and fprintd
   * re-opens the device (often on a different thread) between operations. */
  if(g_loaded){ arm_teb_for_current_thread(); return 0; }
  g_dllpath = dll_path ? dll_path : "ftWbioEngineAdapter.dll";
  register_shims();
  if(load_pe()!=0) return -1;
  void *q=get_export("WbioQueryEngineInterface");
  if(!q) return -2;
  u64 (MS *Query)(void**)=q;
  void *iface=0;
  if((u32)Query(&iface)!=0 || !iface) return -3;
  g_iface=iface;
  *(u64*)(pipeline+0x08)=~0ULL;
  build_storage_vtable();
  *(u64*)(pipeline+0x20)=(u64)g_sensor_vt;
  *(u64*)(pipeline+0x28)=(u64)g_storage_vt;
  u64 (MS *Attach)(void*)=*(void**)((u8*)iface+32+0*8);
  if((u32)Attach(pipeline)!=0) return -4;
  u64 ctx=*(u64*)(pipeline+0x38);
  *(u32*)(ctx+0x24)=ENG_W; *(u32*)(ctx+0x28)=ENG_H;
  g_loaded=1;
  return 0;
}

void ft_engine_close(void){
  /* The engine maps at a fixed base and is loaded once per process; a libfprint
   * device close/reopen must NOT tear it down (and must not clear g_iface, or the
   * next open — which short-circuits on the load-once guard — leaves a null
   * interface and the following engine call segfaults). Intentional no-op. */
}

uint32_t ft_engine_accept(const uint8_t *img,int sw,int sh,uint8_t purpose){
  arm_teb_for_current_thread();   /* ensure %gs + stack bounds describe this thread */
  prepare_frame((const u8*)img, sw, sh);
  int total=build_bir(small, ENG_W, ENG_H);
  u32 rej=0;
  u64 (MS *Accept)(void*,void*,u64,u64,void*)=*(void**)((u8*)g_iface+32+8*8);
  return (u32)Accept(pipeline, birbuf, total, purpose, &rej);
}

void ft_engine_enroll_begin(void){
  arm_teb_for_current_thread();
  g_have_record=0; g_rec_tsize=0;
  u64 (MS *Create)(void*)=*(void**)((u8*)g_iface+32+12*8);
  Create(pipeline);
}

int ft_engine_enroll_update(void){
  arm_teb_for_current_thread();
  u64 (MS *Update)(void*,void*)=*(void**)((u8*)g_iface+32+13*8);
  u64 (MS *Status)(void*,void*)=*(void**)((u8*)g_iface+32+14*8);
  u32 urej=0; u64 uhr=Update(pipeline,&urej);
  if((u32)uhr==0x80098008 || urej) return 2;   /* frame rejected (dup/low quality) */
  u32 srej=0; u64 shr=Status(pipeline,&srej);
  return (u32)shr==0 ? 0 : 1;                    /* 0 complete, 1 need more */
}

static void fill_identity(u8 *id){ memset(id,0,76); *(u32*)id=3; for(int i=0;i<16;i++) id[8+i]=0xA0+i; }

int ft_engine_enroll_commit(uint8_t **out,size_t *outlen){
  arm_teb_for_current_thread();
  u8 id[76]; fill_identity(id);
  g_have_record=0;
  u64 (MS *Commit)(void*,void*,u8)=*(void**)((u8*)g_iface+32+17*8);
  if((u32)Commit(pipeline,id,1)!=0 || !g_have_record) return -1;
  *out=malloc(g_rec_tsize); if(!*out) return -2;
  memcpy(*out, g_rec_template, g_rec_tsize); *outlen=g_rec_tsize;
  return 0;
}

int ft_engine_verify(const uint8_t *tmpl,size_t tmpllen){
  arm_teb_for_current_thread();
  if(tmpllen==0 || tmpllen>sizeof g_rec_template) return 0;
  memcpy(g_rec_template, tmpl, tmpllen); g_rec_tsize=tmpllen; g_have_record=1;
  u8 id[76]; fill_identity(id);
  u8 m=0; u32 ps=0,hs=0,vr=0; void*plp=0,*hp=0;
  u64 (MS *Verify)(void*,void*,u8,void*,void*,void*,void*,void*,void*)=*(void**)((u8*)g_iface+32+10*8);
  Verify(pipeline, id, 1, &m, &ps, &plp, &hs, &hp, &vr);
  return m?1:0;
}
