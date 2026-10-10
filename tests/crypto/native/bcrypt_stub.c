/* Linux ABI shim for the actual Delphi/FPC Windows CNG adapter.
 * Uses maintained OpenSSL AES; tests arguments/lifecycle, not Windows ABI/drivers. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/param_build.h>
#include <openssl/bn.h>
#include <openssl/rsa.h>

static int calls, fail_call, wrong_length, live;
struct algorithm { uint32_t marker; int des; };
struct key { uint8_t secret[24]; void *object; int des; EVP_PKEY *rsa; };
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
    if (!out || (!wide_equal(id,"AES") && !wide_equal(id,"3DES") && !wide_equal(id,"SHA1") && !wide_equal(id,"RSA")) || provider || flags) return failure();
    struct algorithm *a=calloc(1,sizeof(*a)); if (!a) return failure();
    a->marker=0x12345678; a->des=wide_equal(id,"RSA") ? 3 : wide_equal(id,"SHA1") ? 2 : wide_equal(id,"3DES"); *out=a; live++; return 0;
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
    struct key *k=handle; if (k->des==3) EVP_PKEY_free(k->rsa); memset(k->secret,0,24); free(k); live--; return failed ? failure() : 0;
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

/* RSA import/sign/verify branch: consumes the exact CNG key-blob layout. */
static uint32_t little32(const uint8_t *b) {
    return b[0] | ((uint32_t)b[1]<<8) | ((uint32_t)b[2]<<16) | ((uint32_t)b[3]<<24);
}
int32_t BCryptImportKeyPair(void *algorithm,void *import,const uint16_t *type,
                           void **out,const void *input,uint32_t count,uint32_t flags) {
    if (tick()) return failure();
    if (!algorithm || ((struct algorithm *)algorithm)->des!=3 || import || !out || !input || count<24 || flags) return failure();
    int private_key=wide_equal(type,"RSAPRIVATEBLOB");
    if (!private_key && !wide_equal(type,"RSAPUBLICBLOB")) return failure();
    const uint8_t *b=input;
    uint32_t en=little32(b+8),nn=little32(b+12),pn=little32(b+16),qn=little32(b+20);
    if (little32(b)!=(private_key?0x32415352u:0x31415352u) || little32(b+4)!=nn*8 ||
        nn<128 || nn>512 || en<1 || en>8 || count!=24+en+nn+pn+qn ||
        (private_key?(pn!=nn/2 || qn!=nn/2):(pn || qn))) return failure();
    BIGNUM *e=BN_bin2bn(b+24,en,NULL),*n=BN_bin2bn(b+24+en,nn,NULL),*p=NULL,*q=NULL,*d=NULL;
    BIGNUM *pm=NULL,*qm=NULL,*phi=NULL; BN_CTX *bnctx=NULL;
    OSSL_PARAM_BLD *builder=OSSL_PARAM_BLD_new(); OSSL_PARAM *params=NULL;
    EVP_PKEY_CTX *ctx=NULL; EVP_PKEY *rsa=NULL;
    int ok=e && n && builder;
    if (ok && private_key) {
        p=BN_bin2bn(b+24+en+nn,pn,NULL); q=BN_bin2bn(b+24+en+nn+pn,qn,NULL);
        pm=BN_dup(p); qm=BN_dup(q); phi=BN_new(); bnctx=BN_CTX_new();
        ok=p && q && pm && qm && phi && bnctx && BN_sub_word(pm,1)==1 && BN_sub_word(qm,1)==1 && BN_mul(phi,pm,qm,bnctx)==1;
        if (ok) { d=BN_mod_inverse(NULL,e,phi,bnctx); ok=d!=NULL; }
    }
    if (ok) ok=OSSL_PARAM_BLD_push_BN(builder,"n",n)==1 && OSSL_PARAM_BLD_push_BN(builder,"e",e)==1;
    if (ok && private_key) ok=OSSL_PARAM_BLD_push_BN(builder,"d",d)==1 && OSSL_PARAM_BLD_push_BN(builder,"rsa-factor1",p)==1 && OSSL_PARAM_BLD_push_BN(builder,"rsa-factor2",q)==1;
    if (ok) { params=OSSL_PARAM_BLD_to_param(builder); ctx=EVP_PKEY_CTX_new_from_name(NULL,"RSA",NULL); ok=params && ctx; }
    if (ok) ok=EVP_PKEY_fromdata_init(ctx)==1 && EVP_PKEY_fromdata(ctx,&rsa,private_key?EVP_PKEY_KEYPAIR:EVP_PKEY_PUBLIC_KEY,params)==1;
    EVP_PKEY_CTX_free(ctx); OSSL_PARAM_free(params); OSSL_PARAM_BLD_free(builder);
    BN_clear_free(e); BN_clear_free(n); BN_clear_free(p); BN_clear_free(q); BN_clear_free(d);
    BN_clear_free(pm); BN_clear_free(qm); BN_clear_free(phi); BN_CTX_free(bnctx);
    if (!ok) { EVP_PKEY_free(rsa); return failure(); }
    struct key *k=calloc(1,sizeof(*k)); if (!k) { EVP_PKEY_free(rsa); return failure(); }
    k->des=3; k->rsa=rsa; *out=k; live++; return 0;
}
int32_t BCryptSignHash(void *handle,const uint16_t **padding,const void *digest,uint32_t count,
                       void *output,uint32_t outsize,uint32_t *actual,uint32_t flags) {
    if (tick()) return failure();
    struct key *k=handle;
    if (!k || k->des!=3 || !padding || !wide_equal(*padding,"SHA1") || !digest || count!=20 ||
        !output || outsize!=(uint32_t)EVP_PKEY_get_size(k->rsa) || !actual || flags!=2) return failure();
    EVP_PKEY_CTX *ctx=EVP_PKEY_CTX_new_from_pkey(NULL,k->rsa,NULL); if (!ctx) return failure();
    size_t size=outsize;
    int ok=EVP_PKEY_sign_init(ctx)==1 && EVP_PKEY_CTX_set_rsa_padding(ctx,RSA_PKCS1_PADDING)==1 &&
        EVP_PKEY_CTX_set_signature_md(ctx,EVP_sha1())==1 && EVP_PKEY_sign(ctx,output,&size,digest,count)==1;
    EVP_PKEY_CTX_free(ctx); if (!ok) return failure();
    *actual=wrong_length==2 ? (uint32_t)size-1 : (uint32_t)size; return 0;
}
int32_t BCryptVerifySignature(void *handle,const uint16_t **padding,const void *digest,uint32_t count,
                              const void *signature,uint32_t size,uint32_t flags) {
    if (tick()) return failure();
    struct key *k=handle;
    if (!k || k->des!=3 || !padding || !wide_equal(*padding,"SHA1") || !digest || count!=20 ||
        !signature || size!=(uint32_t)EVP_PKEY_get_size(k->rsa) || flags!=2) return failure();
    EVP_PKEY_CTX *ctx=EVP_PKEY_CTX_new_from_pkey(NULL,k->rsa,NULL); if (!ctx) return failure();
    int ok=EVP_PKEY_verify_init(ctx)==1 && EVP_PKEY_CTX_set_rsa_padding(ctx,RSA_PKCS1_PADDING)==1 &&
        EVP_PKEY_CTX_set_signature_md(ctx,EVP_sha1())==1;
    int verified=ok ? EVP_PKEY_verify(ctx,signature,size,digest,count) : -1;
    EVP_PKEY_CTX_free(ctx);
    return verified==1 ? 0 : verified==0 ? (int32_t)UINT32_C(0xc000a000) : failure();
}
