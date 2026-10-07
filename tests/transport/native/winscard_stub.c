/* Linux-only ABI shim for the Windows SDK-shaped boundary. Never ship this DLL. */
#include <stdint.h>
#include <stddef.h>
#include <string.h>

typedef struct { uint32_t protocol, size; } io_request;
typedef struct {
    const uint16_t *reader;
    void *user;
    uint32_t current, event, atr_size;
    uint8_t atr[36];
} reader_state;
_Static_assert(sizeof(io_request) == 8, "SCARD_IO_REQUEST layout");
_Static_assert(sizeof(reader_state) == (sizeof(void *) == 8 ? 64 : 56), "SCARD_READERSTATE layout");
_Static_assert(offsetof(reader_state, current) == 2 * sizeof(void *), "DWORD offset");

static int mode, transmit_calls, list_calls;
static const uintptr_t context = (uintptr_t)UINT64_C(0x100000001);
static const uintptr_t card = (uintptr_t)UINT64_C(0x200000003);
static const uint16_t names[] = {'R',0x00e9,0,'B',0,0};
static const uint8_t atr[] = {0x3b,0x80,0x01,0x81};

void CardTestConfigure(int value) { mode=value; transmit_calls=0; list_calls=0; }
int CardTestCount(int kind) { return kind == 0 ? transmit_calls : list_calls; }

uint32_t SCardEstablishContext(uint32_t scope, void *r1, void *r2, uintptr_t *out) {
    if (scope || r1 || r2 || !out) return 0x80100004u;
    *out=context; return 0;
}
uint32_t SCardReleaseContext(uintptr_t ctx) { return ctx==context ? 0 : 0x80100003u; }
uint32_t SCardListReadersW(uintptr_t ctx, const uint16_t *groups, uint16_t *out, uint32_t *size) {
    if (ctx!=context || groups || !size) return 0x80100004u;
    if (mode==8) return 0x8010002eu;
    if (!out) { *size=6; return 0; }
    ++list_calls;
    if (mode==2 && list_calls==1) { *size=8; return 0x80100008u; }
    if (*size<6) { *size=6; return 0x80100008u; }
    memcpy(out,names,sizeof(names)); *size=6;
    if (mode==1) out[5]='X';
    return 0;
}
uint32_t SCardConnectW(uintptr_t ctx, const uint16_t *name, uint32_t share,
                      uint32_t protocols, uintptr_t *out, uint32_t *protocol) {
    if (ctx!=context || !name || name[0]!='R' || name[1]!=0x00e9 || name[2] ||
        share!=2 || protocols!=3 || !out || !protocol) return 0x80100004u;
    *out=card; *protocol=2;
    return mode==7 ? 0x8010000cu : 0;
}
uint32_t SCardDisconnect(uintptr_t handle, uint32_t action) {
    return handle==card && action<=3 ? 0 : 0x80100004u;
}
uint32_t SCardBeginTransaction(uintptr_t handle) { return handle==card ? 0 : 0x80100003u; }
uint32_t SCardEndTransaction(uintptr_t handle, uint32_t action) {
    return SCardDisconnect(handle,action);
}
uint32_t SCardTransmit(uintptr_t handle, const io_request *send_pci,
                       const uint8_t *send, uint32_t send_size, void *recv_pci,
                       uint8_t *recv, uint32_t *size) {
    ++transmit_calls;
    if (handle!=card || !send_pci || send_pci->protocol!=2 || send_pci->size!=8 ||
        !send || send_size!=5 || send[0]!=0 || send[1]!=0xa4 || recv_pci || !recv || !size)
        return 0x80100004u;
    if (mode==4) { *size+=1; return 0x80100008u; }
    if (mode==3) { *size+=1; return 0; }
    if (*size<2) return 0x80100008u;
    recv[0]=0x90; recv[1]=0; *size=2; return 0;
}
uint32_t SCardStatusW(uintptr_t handle, uint16_t *readers, uint32_t *reader_size,
                      uint32_t *state, uint32_t *protocol, uint8_t *out, uint32_t *size) {
    if (handle!=card || readers || reader_size || state || protocol || !out || !size || *size!=36)
        return 0x80100004u;
    if (mode==5) { *size=37; return 0; }
    memcpy(out,atr,sizeof(atr)); *size=sizeof(atr); return 0;
}
uint32_t SCardGetStatusChangeW(uintptr_t ctx, uint32_t timeout, reader_state *states, uint32_t count) {
    if (ctx!=context || !states || count!=1 || !states->reader || states->user ||
        (states->current & 2) || timeout==UINT32_MAX) return 0x80100004u;
    if (mode==6) return 0x8010000au;
    states->event=0x12340022u;
    states->atr_size=mode==5 ? 37 : sizeof(atr);
    memcpy(states->atr,atr,sizeof(atr)); return 0;
}
uint32_t SCardCancel(uintptr_t ctx) { return ctx==context ? 0 : 0x80100003u; }
