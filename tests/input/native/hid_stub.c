/* Linux ABI shim: exercises native arguments, buffers and cancellation ownership.
   It does not emulate Windows drivers or validate Windows calling conventions. */
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
static _Noreturn void fail_line(int line) { fprintf(stderr,"Native HID shim assertion at line %d\n",line); exit(99); }
typedef struct { uint32_t size; uint16_t vendor,product,version; } Attributes;
typedef struct { uint16_t usage,page,input,output,feature,reserved[17],counts[10]; } Caps;
typedef struct { uint32_t size; uint8_t guid[16]; uint32_t flags; uintptr_t reserved; } IfData;
typedef struct { uintptr_t internal,high; uint32_t offset,offsethigh; uintptr_t event; } Overlap;
_Static_assert(sizeof(Attributes)==12,"HIDD_ATTRIBUTES size");
_Static_assert(sizeof(Caps)==64,"HIDP_CAPS size");
_Static_assert(sizeof(IfData)==32,"x64 interface size");
_Static_assert(sizeof(Overlap)==32,"x64 OVERLAPPED size");
static int mode,counts[16],pending,cancelled;
static uint32_t error_code;
static uint8_t *io_buffer;
static uint32_t io_size;
static int writing;
static const uint16_t path[]={ 'h','i','d',':','t','e','s','t',0 };
void HidTestConfigure(int m) { mode=m; memset(counts,0,sizeof counts); pending=cancelled=0; error_code=0; }
int HidTestCount(int n) { return n>=0 && n<16 ? counts[n] : -1; }
void HidD_GetHidGuid(void *g) { memset(g,0x42,16); }
uint8_t HidD_GetAttributes(uintptr_t h,Attributes *a) {
  ++counts[1]; if(h!=10 || a->size!=12) fail_line(__LINE__);
  if(mode==2) return 0;
  a->vendor=0x1234; a->product=0x5678; a->version=0x100; return 1;
}
uint8_t HidD_GetPreparsedData(uintptr_t h,void **p) { if(h!=10) fail_line(__LINE__);
  *p=(void*)20; return 1; }
uint8_t HidD_FreePreparsedData(void *p) { if(p!=(void*)20) fail_line(__LINE__);
  ++counts[2]; return 1; }
int32_t HidP_GetCaps(void *p,Caps *c) {
  if(p!=(void*)20) fail_line(__LINE__);
  memset(c,0,sizeof *c); c->usage=1;c->page=0xff00;c->input=c->output=c->feature=4;
  return mode==3 ? -1 : 0x110000;
}
uint8_t HidD_GetFeature(uintptr_t h,void *p,uint32_t n) {
  ++counts[3]; if(h!=10 || n!=4 || ((uint8_t*)p)[0]!=7) fail_line(__LINE__);
  if(mode==4) return 0;
  ((uint8_t*)p)[1]=1;((uint8_t*)p)[2]=2;((uint8_t*)p)[3]=3; return 1;
}
uint8_t HidD_SetFeature(uintptr_t h,void *p,uint32_t n) {
  ++counts[4]; if(h!=10 || n!=4 || memcmp(p,"\7\1\2\3",4)) fail_line(__LINE__);
  return mode!=4;
}
uintptr_t SetupDiGetClassDevsW(const uint8_t *g,const uint16_t *e,uintptr_t w,uint32_t flags) {
  if(g[0]!=0x42 || e || w || flags!=0x12) fail_line(__LINE__);
  return mode==12 ? UINTPTR_MAX : 30;
}
int32_t SetupDiEnumDeviceInterfaces(uintptr_t h,void *d,const uint8_t *g,uint32_t i,IfData *data) {
  if(h!=30 || d || g[0]!=0x42 || data->size!=32) fail_line(__LINE__);
  if(i) {error_code=259;return 0;} return 1;
}
int32_t SetupDiGetDeviceInterfaceDetailW(uintptr_t h,IfData *d,void *b,uint32_t size,uint32_t *required,void *dev) {
  if(h!=30 || d->size!=32 || dev) fail_line(__LINE__);
  *required=24;
  if(!b) {error_code=122; return 0;}
  if(size!=24 || *(uint32_t*)b!=8) fail_line(__LINE__);
  memcpy((uint8_t*)b+4,path,sizeof path); return 1;
}
int32_t SetupDiDestroyDeviceInfoList(uintptr_t h) { if(h!=30) fail_line(__LINE__);
  ++counts[5];return 1; }
uintptr_t CreateFileW(const uint16_t *p,uint32_t access,uint32_t share,void *sec,uint32_t disposition,uint32_t flags,uintptr_t tmpl) {
  ++counts[0]; if(memcmp(p,path,sizeof path) || share!=3 || sec || disposition!=3 || tmpl) fail_line(__LINE__);
  if(access) {if(access!=0x80000000 && access!=0xc0000000) fail_line(__LINE__);
  if(flags!=0x40000000) fail_line(__LINE__);}
  else if(flags) fail_line(__LINE__);
  return mode==1 ? UINTPTR_MAX : 10;
}
int32_t CloseHandle(uintptr_t h) {
  if(h==10) {++counts[6];return mode!=11;}
  if(h==40) { if(pending) fail_line(__LINE__);
  ++counts[7];return 1;}
  fail_line(__LINE__);
}
uintptr_t CreateEventW(void *sec,int32_t reset,int32_t state,const uint16_t *name) {
  if(sec || !reset || state || name) fail_line(__LINE__);
  return 40;
}
static int32_t transfer(uintptr_t h,void *b,uint32_t n,uint32_t *done,Overlap *o,int w) {
  ++counts[w?9:8]; if(h!=10 || n!=4 || !o || o->event!=40 || o->internal || o->offset) fail_line(__LINE__);
  if(w && memcmp(b,"\7\1\2\3",4)) fail_line(__LINE__);
  if(mode==5) {error_code=5;return 0;}
  if((mode>=6 && mode<=8) || mode==13) {pending=1;io_buffer=b;io_size=n;writing=w;error_code=997;return 0;}
  if(!w) memcpy(b,"\7\1\2\3",4);
  *done=mode==9?3:4;return 1;
}
int32_t ReadFile(uintptr_t h,void *b,uint32_t n,uint32_t *done,Overlap *o) { return transfer(h,b,n,done,o,0); }
int32_t WriteFile(uintptr_t h,const void *b,uint32_t n,uint32_t *done,Overlap *o) { return transfer(h,(void*)b,n,done,o,1); }
uint32_t GetLastError(void) { return error_code; }
uint32_t WaitForSingleObject(uintptr_t h,uint32_t ms) { if(h!=40 || ms!=123 || !pending) fail_line(__LINE__);return mode==7?258:mode==8?UINT32_MAX:0; }
int32_t CancelIoEx(uintptr_t h,Overlap *o) { if(h!=10 || !o || !pending) fail_line(__LINE__);++counts[10];cancelled=1;return 1; }
int32_t GetOverlappedResult(uintptr_t h,Overlap *o,uint32_t *done,int32_t wait) {
  if(h!=10 || !o || !pending || (!!wait != !!cancelled)) fail_line(__LINE__);
  ++counts[11];
  if(mode==13 && !cancelled) {error_code=996;return 0;}
  if(cancelled) {pending=0;error_code=995;return 0;}
  if(!writing) memcpy(io_buffer,"\7\1\2\3",io_size);
  *done=io_size;pending=0;return 1;
}
