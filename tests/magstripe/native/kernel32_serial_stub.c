#include <stdint.h>
#include <stddef.h>
#include <string.h>

typedef struct {
    uint32_t length, baud, flags;
    uint16_t reserved, xon_limit, xoff_limit;
    uint8_t byte_size, parity, stop, xon, xoff, error, eof, event;
    uint16_t reserved1;
} serial_dcb;
typedef struct {
    uint32_t read_interval, read_multiplier, read_constant, write_multiplier, write_constant;
} serial_timeouts;
_Static_assert(sizeof(serial_dcb) == 28, "Windows DCB size");
_Static_assert(offsetof(serial_dcb, byte_size) == 18, "Windows DCB byte size offset");
_Static_assert(sizeof(serial_timeouts) == 20, "Windows COMMTIMEOUTS size");

static int mode, counts[8];
static uint32_t deadline;
static unsigned step, reply_offset, reply_size;
static uint8_t reply[16];
static const uintptr_t handle = (uintptr_t)UINT64_C(0x200000003);

void CardSerialTestConfigure(int value) {
    mode = value;
    memset(counts, 0, sizeof(counts));
    deadline = 0;
    step = reply_offset = reply_size = 0;
}
int CardSerialTestCount(int kind) { return kind >= 0 && kind < 8 ? counts[kind] : -1; }
uint32_t CardSerialTestDeadline(void) { return deadline; }

uintptr_t CreateFileW(const uint16_t *name, uint32_t access, uint32_t share,
                     const void *security, uint32_t creation, uint32_t flags, uintptr_t template_handle) {
    static const uint16_t expected[] = {'\\','\\','.','\\','C','O','M','1','2',0};
    counts[0]++;
    if (!name || memcmp(name, expected, sizeof(expected)) || access != UINT32_C(0xC0000000) ||
        share || security || creation != 3 || flags || template_handle || mode == 1)
        return UINTPTR_MAX;
    return handle;
}
int32_t CloseHandle(uintptr_t value) {
    counts[1]++;
    return value == handle && mode != 9;
}
int32_t SetCommState(uintptr_t value, const serial_dcb *state) {
    counts[2]++;
    if (value != handle || !state || state->length != 28 || state->baud != 9600 || state->flags != (mode == 21 ? 3u : 1u) ||
        state->reserved || state->reserved1 || state->byte_size != (mode == 21 ? 7u : 8u) || state->parity != (mode == 21 ? 1u : 0u) || state->stop ||
        state->xon != 0x11 || state->xoff != 0x13 || state->xon_limit || state->xoff_limit)
        return 0;
    return mode != 2;
}
int32_t SetCommTimeouts(uintptr_t value, const serial_timeouts *timeouts) {
    counts[3]++;
    if (value != handle || !timeouts || timeouts->read_interval || timeouts->read_multiplier ||
        timeouts->write_multiplier || !timeouts->read_constant ||
        timeouts->read_constant != timeouts->write_constant || timeouts->read_constant > 600000)
        return 0;
    deadline = timeouts->read_constant;
    return mode != 3;
}
int32_t PurgeComm(uintptr_t value, uint32_t flags) {
    counts[4]++;
    return value == handle && flags == 8 && mode != 4;
}
static int protocol_send(const uint8_t *bytes, uint32_t size) {
    static const uint8_t commands[][18] = {
        {0x1B,0x61}, {0x1B,0x65}, {0x1B,0x74}, {0x1B,0x6F,7,5,5}, {0x1B,0x62,0x4B},
        {0x1B,0x78}, {0x1B,0x64},
        {0x1B,0x77,0x1B,0x73,0x1B,1,'0','1',0x1B,2,'2','3',0x1B,3,'4','5','?',0x1C},
        {0x1B,0x61}
    };
    static const uint8_t command_sizes[] = {2,2,2,5,3,2,2,18,2};
    static const uint8_t replies[][5] = {
        {0}, {0x1B,0x79}, {0x1B,0x33,0x53}, {0x1B,0x30,7,5,5}, {0x1B,0x30},
        {0x1B,0x30}, {0x1B,0x48}, {0x1B,0x30}, {0}
    };
    static const uint8_t reply_sizes[] = {0,2,3,5,2,2,2,2,0};
    if (step >= 9 || size != command_sizes[step] || memcmp(bytes, commands[step], size) || reply_offset != reply_size)
        return 0;
    reply_offset = 0;
    reply_size = reply_sizes[step];
    memcpy(reply, replies[step], reply_size);
    step++;
    return 1;
}
static int protocol_7hl_send(const uint8_t *bytes, uint32_t size) {
    static const uint8_t commands[][7] = {
        {0x7F}, {2,0x23,3,0x22}, {2,0x3C,'2','5','5',3,0x0F}, {2,0x3E,3,0x3F},
        {2,0x4F,3,0x4E}, {2,0x6E,3,0x6F}, {2,0x42,3,0x43},
        {2,'2','3',4,3,4}, {2,0x40,3,0x41}, {2,0x52,3,0x53}, {0x7F}
    };
    static const uint8_t command_sizes[] = {1,4,7,4,4,4,4,6,4,4,1};
    static const uint8_t replies[][8] = {
        {0x3A}, {2,0x77,3,0x76}, {2,0x5E,3,0x5F}, {2,'2','5','5',3,0x33},
        {2,0x5E,3,0x5F}, {2,0x5E,3,0x5F}, {2,0x5E,3,0x5F}, {2,0x5E,3,0x5F},
        {2,0x5E,3,0x5F,2,0x5E,3,0x5F}, {2,'2','3',3,0}, {0}
    };
    static const uint8_t reply_sizes[] = {1,4,4,6,4,4,4,4,8,5,0};
    if (step >= 11 || size != command_sizes[step] || memcmp(bytes, commands[step], size) || reply_offset != reply_size)
        return 0;
    reply_offset = 0;
    reply_size = reply_sizes[step];
    memcpy(reply, replies[step], reply_size);
    step++;
    return 1;
}
int32_t WriteFile(uintptr_t value, const uint8_t *bytes, uint32_t size, uint32_t *written, const void *overlapped) {
    counts[5]++;
    if (value != handle || !bytes || !size || size > 4096 || !written || overlapped) return 0;
    if (mode == 20 && !protocol_send(bytes, size)) return 0;
    if (mode == 21 && !protocol_7hl_send(bytes, size)) return 0;
    *written = mode == 5 ? size - 1 : (mode == 10 ? size + 1 : size);
    return mode != 11;
}
int32_t ReadFile(uintptr_t value, uint8_t *bytes, uint32_t size, uint32_t *received, const void *overlapped) {
    counts[6]++;
    if (value != handle || !bytes || size != 1 || !received || overlapped) return 0;
    if (mode == 20 || mode == 21) {
        if (reply_offset >= reply_size) return 0;
        bytes[0] = reply[reply_offset++];
    } else bytes[0] = 0x79;
    *received = mode == 6 ? 0 : (mode == 7 ? 2 : 1);
    return mode != 8;
}
uint32_t GetLastError(void) { return 5; }
uint64_t GetTickCount64(void) { counts[7]++; return UINT64_C(0x100000001); }
