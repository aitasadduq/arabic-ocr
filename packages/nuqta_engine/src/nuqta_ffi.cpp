// C ABI over nuqta_core for dart:ffi. See nuqta_ffi.h.
#include "nuqta_ffi.h"

#include <algorithm>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_set>
#include <vector>

#include <dlfcn.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#include "llama.h"
#include "mtmd-helper.h"
#include "nuqta_core.h"

#ifndef NUQTA_LLAMA_COMMIT
#define NUQTA_LLAMA_COMMIT "unknown"
#endif

namespace {

std::atomic<nuqta_event_fn> g_cb{nullptr};
std::mutex g_cancel_mu;
std::unordered_set<int32_t> g_cancelled;

char * dup_bytes(const std::string & s) {
    char * p = static_cast<char *>(malloc(s.size() + 1));
    if (!p) return nullptr;
    memcpy(p, s.data(), s.size());
    p[s.size()] = '\0';
    return p;
}

void emit(int32_t job, int32_t kind, int32_t value, const std::string * text = nullptr) {
    nuqta_event_fn cb = g_cb.load();
    if (!cb) return;
    char * p = text ? dup_bytes(*text) : nullptr;
    cb(job, kind, value, p, p ? (int32_t) text->size() : 0);
}

bool is_cancelled(int32_t job) {
    std::lock_guard<std::mutex> lk(g_cancel_mu);
    return g_cancelled.count(job) != 0;
}

void forget(int32_t job) {
    std::lock_guard<std::mutex> lk(g_cancel_mu);
    g_cancelled.erase(job);
}

// errors only (llama.cpp warns on every M-RoPE batch); NUQTA_LOG=1 shows everything
void log_cb(ggml_log_level level, const char * text, void *) {
    if (level < GGML_LOG_LEVEL_ERROR && !getenv("NUQTA_LOG")) return;
#ifdef __ANDROID__
    __android_log_print(ANDROID_LOG_WARN, "nuqta", "%s", text);
#else
    fputs(text, stderr);
#endif
}

std::string stats_json(const nuqta::Stats & st) {
    char buf[256];
    snprintf(buf, sizeof(buf),
             "{\"image_tokens\":%d,\"out_tokens\":%d,\"encode_s\":%.3f,\"gen_s\":%.3f,\"first_s\":%.3f,\"strips\":%d}",
             st.image_tokens, st.out_tokens, st.encode_s, st.gen_s, st.first_s, st.strips);
    return buf;
}

std::string library_dir() {
    Dl_info info;
    if (dladdr(reinterpret_cast<void *>(&nuqta_version), &info) == 0 || !info.dli_fname) return "";
    std::string path(info.dli_fname);
    const size_t slash = path.find_last_of('/');
    return slash == std::string::npos ? "" : path.substr(0, slash);
}

}  // namespace

extern "C" {

void nuqta_set_event_callback(nuqta_event_fn fn) {
    g_cb.store(fn);
}

void nuqta_load_async(int32_t job, const char * model_path, const char * mmproj_path, int32_t n_threads,
                      int32_t image_max_tokens, const char * backend_dir) {
    std::string model(model_path ? model_path : ""), mmproj(mmproj_path ? mmproj_path : "");
    std::string dir(backend_dir ? backend_dir : "");
#ifdef __ANDROID__
    if (dir.empty()) dir = library_dir();
#endif
    const int threads = n_threads > 0 ? n_threads : nuqta_default_threads();
    std::thread([=] {
        llama_log_set(log_cb, nullptr);
        mtmd_helper_log_set(log_cb, nullptr);
        std::string err;
        const bool ok = nuqta::load(model, mmproj, threads, image_max_tokens, dir, err);
        emit(job, NUQTA_EVENT_LOADED, ok ? 1 : 0, ok ? nullptr : &err);
    }).detach();
}

void nuqta_read_async(int32_t job, const uint8_t * pixels, int32_t w, int32_t h, int32_t channels,
                      const char * prompt_c, int32_t max_new_tokens, int32_t strips) {
    if (!pixels || w <= 0 || h <= 0 || (channels != 3 && channels != 4)) {
        const std::string err = "invalid image";
        emit(job, NUQTA_EVENT_DONE, 0, &err);
        return;
    }
    // copy to packed RGB now: the caller's buffer is only valid during this call
    const size_t n = (size_t) w * h;
    auto rgb = std::make_shared<std::vector<uint8_t>>(n * 3);
    uint8_t * out = rgb->data();
    if (channels == 3) {
        memcpy(out, pixels, n * 3);
    } else {
        for (size_t i = 0; i < n; i++) {
            const uint8_t * px = pixels + i * 4;
            const unsigned a = px[3];
            for (int c = 0; c < 3; c++) out[i * 3 + c] = (uint8_t) ((px[c] * a + 255 * (255 - a) + 127) / 255);
        }
    }
    std::string prompt(prompt_c ? prompt_c : "");
    std::thread([=] {
        nuqta::Stats st;
        std::string err;
        const bool ok = nuqta::read(
            rgb->data(), w, h, prompt, max_new_tokens, strips != 0,
            [&](int stage) { emit(job, NUQTA_EVENT_STAGE, stage); },
            [&](const std::string & piece) {
                if (is_cancelled(job)) return false;
                emit(job, NUQTA_EVENT_TEXT, 0, &piece);
                return !is_cancelled(job);
            },
            st, err);
        const bool cancelled = is_cancelled(job);
        forget(job);
        if (!ok) {
            emit(job, NUQTA_EVENT_DONE, 0, &err);
        } else {
            const std::string json = stats_json(st);
            emit(job, NUQTA_EVENT_DONE, cancelled ? 2 : 1, &json);
        }
    }).detach();
}

void nuqta_cancel(int32_t job) {
    std::lock_guard<std::mutex> lk(g_cancel_mu);
    g_cancelled.insert(job);
}

int32_t nuqta_is_loaded(void) {
    return nuqta::loaded() ? 1 : 0;
}

void nuqta_unload(void) {
    nuqta::unload();
}

void nuqta_free(void * p) {
    free(p);
}

int32_t nuqta_default_threads(void) {
#ifdef __APPLE__
    return 4;  // the model runs on the GPU; these threads only feed it
#else
    // the fast cores only: on big.LITTLE phones the small cores slow every step down
    const int n = (int) std::thread::hardware_concurrency();
    std::vector<long> freqs;
    for (int i = 0; i < n; i++) {
        std::ifstream in("/sys/devices/system/cpu/cpu" + std::to_string(i) + "/cpufreq/cpuinfo_max_freq");
        long f = 0;
        if (in >> f && f > 0) freqs.push_back(f);
    }
    if (freqs.empty()) return std::clamp(n, 2, 4);
    const long top = *std::max_element(freqs.begin(), freqs.end());
    const int fast = (int) std::count_if(freqs.begin(), freqs.end(), [&](long f) { return f * 4 >= top * 3; });
    return std::clamp(fast, 2, 6);
#endif
}

char * nuqta_library_dir(void) {
    return dup_bytes(library_dir());
}

const char * nuqta_version(void) {
    return "nuqta_engine 1.0.0 (llama.cpp " NUQTA_LLAMA_COMMIT ")";
}

}  // extern "C"
