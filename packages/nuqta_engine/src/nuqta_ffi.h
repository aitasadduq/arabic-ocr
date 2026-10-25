// C ABI over the Nuqta core engine, for dart:ffi.
//
// Every long-running call (load, read) runs on its own native thread and returns
// at once. Progress is reported through a single event callback, which is called
// from that worker thread. On the Dart side it must be a
// NativeCallable.listener. Text passed to the callback is malloc'd and owned by
// the receiver, which releases it with nuqta_free().
#pragma once

#include <stdint.h>

#if defined(_WIN32)
#define NUQTA_API __declspec(dllexport)
#else
#define NUQTA_API __attribute__((visibility("default"))) __attribute__((used))
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum nuqta_event_kind {
    NUQTA_EVENT_LOADED = 0,  // value: 1 ok, 0 failed (text: error message)
    NUQTA_EVENT_STAGE = 1,   // value: 0 reading the image, 1 writing
    NUQTA_EVENT_TEXT = 2,    // text: the next piece of output (complete UTF-8)
    NUQTA_EVENT_DONE = 3,    // value: 1 finished, 2 cancelled, 0 failed (text: error message or stats JSON)
};

// job: the id the caller passed; kind: nuqta_event_kind; text: may be null, otherwise
// text_len bytes of UTF-8 (NUL-terminated as well) that the receiver must nuqta_free().
typedef void (*nuqta_event_fn)(int32_t job, int32_t kind, int32_t value, char * text, int32_t text_len);

NUQTA_API void nuqta_set_event_callback(nuqta_event_fn fn);

// Loads the model and its vision projector on a worker thread. backend_dir may be
// empty: on Android the engine then uses the directory this library was loaded
// from (where the CPU backend variants live). n_threads <= 0 picks the fast cores.
NUQTA_API void nuqta_load_async(int32_t job, const char * model_path, const char * mmproj_path, int32_t n_threads,
                                int32_t image_max_tokens, const char * backend_dir);

// Reads one image. pixels: w*h*channels bytes (channels 3 = RGB, 4 = RGBA, alpha is
// composited onto white); the buffer is copied before the call returns.
NUQTA_API void nuqta_read_async(int32_t job, const uint8_t * pixels, int32_t w, int32_t h, int32_t channels,
                                const char * prompt, int32_t max_new_tokens, int32_t strips);

// Stops a running or queued read at the next written piece.
NUQTA_API void nuqta_cancel(int32_t job);

NUQTA_API int32_t nuqta_is_loaded(void);

// Frees the model. Blocks until a running read has finished.
NUQTA_API void nuqta_unload(void);

NUQTA_API void nuqta_free(void * p);

// Number of fast cores (big.LITTLE aware), clamped to 2..6.
NUQTA_API int32_t nuqta_default_threads(void);

// Directory of this shared library ("" when unknown). Caller frees.
NUQTA_API char * nuqta_library_dir(void);

NUQTA_API const char * nuqta_version(void);

#ifdef __cplusplus
}
#endif
