/* Linux ABI shim for the actual Delphi/FPC Windows CNG adapter.
 * Uses maintained OpenSSL AES; tests arguments/lifecycle, not Windows ABI/drivers. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

static int calls, fail_call, wrong_length, live;
struct algorithm { uint32_t marker; int des; };
struct key { uint8_t secret[24]; void *object; int des; };
static int32_t failure(void) { return (int32_t)UINT32_C(0xc0000001); }
static int tick(void) { return ++calls == fail_call; }
static int wide_equal(const uint16_t *value, const char *expected) {
    if (!value) return 0;
    while (*expected) if (*value++ != (uint8_t)*expected++) return 0;
    return *value == 0;
}
void test_crypto_reset(int fail, int wrong) { calls=0; fail_call=fail; wrong_length=wrong; }
int test_crypto_live(void) { return live; }
int test_crypto_calls(void) { return calls; }
int32_t BCryptOpenAlgorithmProvider(void **out, const uint16_t *id,
                                   const uint16_t *provider, uint32_t flags) {
    if (tick()) return failure();
    if (!out || (!wide_equal(id,"AES") && !wide_equal(id,"3DES") && !wide_equal(id,"SHA1")) || provider || flags) return failure();
    struct algorithm *a=calloc(1,sizeof(*a)); if (!a) return failure();
    a->marker=0x12345678; a->des=wide_equal(id,"SHA1") ? 2 : wide_equal(id,"3DES"); *out=a; live++; return 0;
}
int32_t BCryptSetProperty(void *handle, const uint16_t *name, const void *data,
                          uint32_t count, uint32_t flags) {
    if (tick()) return failure();
    if (!handle || !wide_equal(name,"ChainingMode") ||
        !wide_equal(data,"ChainingModeCBC") || count!=32 || flags) return failure();
    return 0;
}
int32_t BCryptGetProperty(void *handle, const uint16_t *name, void *out,
                          uint32_t count, uint32_t *received, uint32_t flags) {
    if (tick()) return failure();
    if (!handle || !wide_equal(name,"ObjectLength") || !out || count!=4 || !received || flags) return failure();
    *(uint32_t *)out=64; *received=wrong_length==1 ? 3 : 4; return 0;
}
int32_t BCryptGenerateSymmetricKey(void *algorithm, void **out, void *object,
                                  uint32_t object_length, const void *secret,
                                  uint32_t secret_length, uint32_t flags) {
    if (tick()) return failure();
    if (!algorithm || !out || !object || object_length!=64 || !secret || secret_length!=(((struct algorithm *)algorithm)->des?24u:16u) || flags) return failure();
    struct key *k=calloc(1,sizeof(*k)); if (!k) return failure();
    k->des=((struct algorithm *)algorithm)->des;memcpy(k->secret,secret,secret_length); k->object=object; memset(object,0x5a,64); *out=k; live++; return 0;
}
static int32_t crypt(void *handle,const void *input,uint32_t length,void *padding,
                     void *iv,uint32_t iv_length,void *output,uint32_t output_length,
                     uint32_t *received,uint32_t flags,int encrypt) {
    if (tick()) return failure();
    if (!handle) return failure();
    struct key *k=handle; uint32_t block=k->des?8u:16u;
    if (!input || !length || length%block || padding || !iv || iv_length!=block ||
        !output || output_length!=length || !received || flags) return failure();
    EVP_CIPHER_CTX *ctx=EVP_CIPHER_CTX_new(); if (!ctx) return failure();
    int first=0,last=0;
    int ok=EVP_CipherInit_ex(ctx,k->des?EVP_des_ede3_cbc():EVP_aes_128_cbc(),NULL,k->secret,iv,encrypt)==1 &&
           EVP_CIPHER_CTX_set_padding(ctx,0)==1 &&
           EVP_CipherUpdate(ctx,output,&first,input,(int)length)==1 &&
           EVP_CipherFinal_ex(ctx,(uint8_t *)output+first,&last)==1;
    EVP_CIPHER_CTX_free(ctx); memset(iv,0xa5,block); /* CNG may mutate its supplied IV. */
    if (!ok || first+last!=(int)length) return failure();
    *received=wrong_length==2 ? length-1 : length; return 0;
}
int32_t BCryptEncrypt(void *k,const void *in,uint32_t n,void *pad,void *iv,uint32_t ivn,
                      void *out,uint32_t outn,uint32_t *got,uint32_t f) {
    return crypt(k,in,n,pad,iv,ivn,out,outn,got,f,1);
}
int32_t BCryptDecrypt(void *k,const void *in,uint32_t n,void *pad,void *iv,uint32_t ivn,
                      void *out,uint32_t outn,uint32_t *got,uint32_t f) {
    return crypt(k,in,n,pad,iv,ivn,out,outn,got,f,0);
}
int32_t BCryptDestroyKey(void *handle) {
    int failed=tick(); if (!handle) return failure();
    struct key *k=handle; memset(k->secret,0,24); free(k); live--; return failed ? failure() : 0;
}
int32_t BCryptCloseAlgorithmProvider(void *handle,uint32_t flags) {
    int failed=tick(); if (!handle || flags) return failure();
    free(handle); live--; return failed ? failure() : 0;
}
int32_t BCryptGenRandom(void *algorithm,void *out,uint32_t count,uint32_t flags) {
    if (tick()) return failure();
    if (algorithm || !out || !count || flags!=2 || RAND_bytes(out,(int)count)!=1) return failure();
    return 0;
}

/* SHA-1 branch used only by explicit EMV Option B derivation tests. */
struct hash { EVP_MD_CTX *ctx; };
int32_t BCryptCreateHash(void *algorithm,void **out,void *object,uint32_t object_length,
                         const void *secret,uint32_t secret_length,uint32_t flags) {
    if (tick()) return failure();
    if (!algorithm || ((struct algorithm *)algorithm)->des!=2 || !out || object ||
        object_length || secret || secret_length || flags) return failure();
    struct hash *h=calloc(1,sizeof(*h)); if (!h) return failure();
    h->ctx=EVP_MD_CTX_new();
    if (!h->ctx || EVP_DigestInit_ex(h->ctx,EVP_sha1(),NULL)!=1) {
        EVP_MD_CTX_free(h->ctx); free(h); return failure();
    }
    *out=h; live++; return 0;
}
int32_t BCryptHashData(void *handle,const void *input,uint32_t count,uint32_t flags) {
    if (tick()) return failure();
    if (!handle || !input || !count || flags) return failure();
    return EVP_DigestUpdate(((struct hash *)handle)->ctx,input,count)==1 ? 0 : failure();
}
int32_t BCryptFinishHash(void *handle,void *output,uint32_t count,uint32_t flags) {
    if (tick()) return failure();
    if (!handle || !output || count!=20 || flags) return failure();
    unsigned int received=0;
    return EVP_DigestFinal_ex(((struct hash *)handle)->ctx,output,&received)==1 && received==20 ? 0 : failure();
}
int32_t BCryptDestroyHash(void *handle) {
    int failed=tick(); if (!handle) return failure();
    struct hash *h=handle; EVP_MD_CTX_free(h->ctx); free(h); live--; return failed ? failure() : 0;
}
