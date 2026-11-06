#include "audio_level_plugin.h"

#include <audioclient.h>
#include <mmdeviceapi.h>
// Needs audioclient.h and mmdeviceapi.h before it.
#include <audioclientactivationparams.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdlib>

// Nothing in this file writes to stdout/stderr or touches the console: the
// release build has none, and an earlier start-up crash came from exactly
// that. Failures are reported to Dart as error codes only.

namespace {

constexpr UINT kMsgStarted = WM_APP + 41;  // wparam: 0 ok, 1 unsupported, 2 failed
constexpr UINT kMsgWindows = WM_APP + 42;
constexpr UINT kMsgLost = WM_APP + 43;

constexpr int kStartOk = 0;
constexpr int kStartUnsupported = 1;
constexpr int kStartFailed = 2;

// Process loopback exists from Windows 10 build 20348 (Windows 11).
constexpr DWORD kMinBuild = 20348;

constexpr DWORD kSampleRate = 48000;
constexpr WORD kChannels = 2;
// One figure per tenth of a second, the same step as the Media3 meter.
constexpr int kWindowFrames = kSampleRate / 10;
constexpr double kHighPassHz = 200.0;
constexpr double kLowPassHz = 3500.0;
constexpr double kFloorDb = -120.0;
constexpr double kPi = 3.14159265358979323846;

// Windows go to Dart about three times a second.
constexpr int64_t kBatchEveryUs = 300000;
// A packet that starts further than this from where the last one ended means
// the capture jumped; the running window is dropped and time is re-anchored.
constexpr int64_t kGapToleranceUs = 40000;
// Old windows are dropped rather than kept if the platform thread never takes
// them (a minute's worth).
constexpr size_t kMaxQueued = 600;
constexpr DWORD kActivateTimeoutMs = 5000;

constexpr wchar_t kWindowClass[] = L"LumoraAudioLevelSink";

// The same clock the Dart side is given: QueryPerformanceCounter in
// microseconds. Split so a long uptime cannot overflow.
int64_t NowUs() {
  static const int64_t freq = [] {
    LARGE_INTEGER f;
    QueryPerformanceFrequency(&f);
    return f.QuadPart > 0 ? f.QuadPart : int64_t{1};
  }();
  LARGE_INTEGER c;
  QueryPerformanceCounter(&c);
  return (c.QuadPart / freq) * 1000000 + (c.QuadPart % freq) * 1000000 / freq;
}

bool BuildAtLeast(DWORD build) {
  using RtlGetVersionFn = LONG(WINAPI*)(OSVERSIONINFOW*);
  HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
  if (ntdll == nullptr) return false;
  auto fn = reinterpret_cast<RtlGetVersionFn>(
      GetProcAddress(ntdll, "RtlGetVersion"));
  if (fn == nullptr) return false;
  OSVERSIONINFOW info = {};
  info.dwOSVersionInfoSize = sizeof(info);
  if (fn(&info) != 0) return false;
  return info.dwMajorVersion > 10 ||
         (info.dwMajorVersion == 10 && info.dwBuildNumber >= build);
}

// ActivateAudioInterfaceAsync reports back on one of its own threads, so the
// handler has to be agile (free-threaded) or the call fails.
class ActivationHandler final : public IActivateAudioInterfaceCompletionHandler,
                                public IAgileObject {
 public:
  ActivationHandler() : done_(CreateEventW(nullptr, TRUE, FALSE, nullptr)) {}

  HANDLE done() const { return done_; }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
    if (out == nullptr) return E_POINTER;
    if (iid == __uuidof(IUnknown) ||
        iid == __uuidof(IActivateAudioInterfaceCompletionHandler)) {
      *out = static_cast<IActivateAudioInterfaceCompletionHandler*>(this);
    } else if (iid == __uuidof(IAgileObject)) {
      *out = static_cast<IAgileObject*>(this);
    } else {
      *out = nullptr;
      return E_NOINTERFACE;
    }
    AddRef();
    return S_OK;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return ++refs_; }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG left = --refs_;
    if (left == 0) delete this;
    return left;
  }
  HRESULT STDMETHODCALLTYPE
  ActivateCompleted(IActivateAudioInterfaceAsyncOperation*) override {
    if (done_ != nullptr) SetEvent(done_);
    return S_OK;
  }

 private:
  ~ActivationHandler() {
    if (done_ != nullptr) CloseHandle(done_);
  }
  std::atomic<ULONG> refs_{1};
  HANDLE done_;
};

template <typename T>
void SafeRelease(T*& p) {
  if (p != nullptr) {
    p->Release();
    p = nullptr;
  }
}

// Speech-band level, one tenth of a second at a time. The same idea as the
// Media3 meter: both channels mixed to mono, a high-pass and a low-pass to
// keep what voices live in (rumble and hiss out), then the RMS in dBFS.
class SpeechMeter {
 public:
  SpeechMeter() {
    const double dt = 1.0 / kSampleRate;
    const double hp_rc = 1.0 / (2.0 * kPi * kHighPassHz);
    const double lp_rc = 1.0 / (2.0 * kPi * kLowPassHz);
    hp_a_ = hp_rc / (hp_rc + dt);
    lp_alpha_ = dt / (lp_rc + dt);
  }

  // Forgets the running window and the filters, for a new stretch of audio.
  void Reset() {
    hp_prev_ = x_prev_ = lp_ = sum_ = 0.0;
    count_ = 0;
  }

  // Adds a frame (mono). True when a window just closed; [db] has its level.
  bool Add(double x, double* db) {
    const double hp = hp_a_ * (hp_prev_ + x - x_prev_);
    x_prev_ = x;
    hp_prev_ = hp;
    lp_ += lp_alpha_ * (hp - lp_);
    sum_ += lp_ * lp_;
    if (++count_ < kWindowFrames) return false;
    const double rms = std::sqrt(sum_ / count_);
    sum_ = 0.0;
    count_ = 0;
    *db = rms > 1e-6 ? std::max(kFloorDb, 20.0 * std::log10(rms)) : kFloorDb;
    return true;
  }

 private:
  double hp_a_ = 0, lp_alpha_ = 0;
  double hp_prev_ = 0, x_prev_ = 0, lp_ = 0, sum_ = 0;
  int count_ = 0;
};

}  // namespace

AudioLevelPlugin::AudioLevelPlugin(flutter::BinaryMessenger* messenger) {
  method_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "lumora/audio_levels",
      &flutter::StandardMethodCodec::GetInstance());
  method_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<Result> result) {
        HandleCall(call, std::move(result));
      });

  events_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      messenger, "lumora/audio_levels/events",
      &flutter::StandardMethodCodec::GetInstance());
  events_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue*,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     sink)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            sink_ = std::move(sink);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            // Nobody listens any more: nothing to measure for.
            sink_.reset();
            Stop();
            return nullptr;
          }));
}

AudioLevelPlugin::~AudioLevelPlugin() {
  method_->SetMethodCallHandler(nullptr);
  events_->SetStreamHandler(nullptr);
  Stop();
  sink_.reset();
  if (message_window_ != nullptr) {
    DestroyWindow(message_window_);
    message_window_ = nullptr;
  }
}

void AudioLevelPlugin::HandleCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<Result> result) {
  if (call.method_name() == "start") {
    Start(std::move(result));
  } else if (call.method_name() == "stop") {
    Stop();
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

bool AudioLevelPlugin::EnsureMessageWindow() {
  if (message_window_ != nullptr) return true;
  HINSTANCE instance = GetModuleHandleW(nullptr);
  WNDCLASSW cls = {};
  cls.lpfnWndProc = MessageProc;
  cls.hInstance = instance;
  cls.lpszClassName = kWindowClass;
  RegisterClassW(&cls);  // Already registered is fine.
  message_window_ =
      CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                      nullptr, instance, nullptr);
  if (message_window_ == nullptr) return false;
  SetWindowLongPtrW(message_window_, GWLP_USERDATA,
                    reinterpret_cast<LONG_PTR>(this));
  return true;
}

void AudioLevelPlugin::Start(std::unique_ptr<Result> result) {
  if (running_) {
    result->Success(flutter::EncodableValue(true));
    return;
  }
  if (pending_start_ || thread_.joinable()) {
    result->Error("busy", "Audio capture is already starting.");
    return;
  }
  if (!EnsureMessageWindow()) {
    result->Error("failed", "Could not create the capture message window.");
    return;
  }
  stop_event_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (stop_event_ == nullptr) {
    result->Error("failed", "Could not create the stop event.");
    return;
  }
  {
    std::lock_guard<std::mutex> lock(mutex_);
    queue_.clear();
  }
  const uint32_t generation = ++generation_;
  pending_start_ = std::move(result);
  try {
    thread_ = std::thread([this, generation] { CaptureMain(generation); });
  } catch (...) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
    auto pending = std::move(pending_start_);
    pending->Error("failed", "Could not start the capture thread.");
  }
}

void AudioLevelPlugin::Stop() {
  ++generation_;
  if (thread_.joinable()) {
    SetEvent(stop_event_);
    thread_.join();
  }
  if (stop_event_ != nullptr) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }
  running_ = false;
  if (pending_start_) {
    auto pending = std::move(pending_start_);
    pending->Error("stopped", "Capture was stopped before it started.");
  }
  std::lock_guard<std::mutex> lock(mutex_);
  queue_.clear();
}

void AudioLevelPlugin::PostToPlatform(uint32_t generation, UINT message,
                                      WPARAM wparam) {
  // The generation travels in lparam so a message from a capture that was
  // since stopped is recognised and dropped.
  PostMessageW(message_window_, message, wparam,
               static_cast<LPARAM>(generation));
}

LRESULT CALLBACK AudioLevelPlugin::MessageProc(HWND hwnd, UINT message,
                                               WPARAM wparam, LPARAM lparam) {
  auto* self = reinterpret_cast<AudioLevelPlugin*>(
      GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (self != nullptr && message >= kMsgStarted && message <= kMsgLost) {
    if (static_cast<uint32_t>(lparam) == self->generation_.load()) {
      if (message == kMsgStarted) {
        self->OnStarted(static_cast<int>(wparam));
      } else if (message == kMsgWindows) {
        self->OnWindows();
      } else {
        self->SendLost();
      }
    }
    return 0;
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

void AudioLevelPlugin::OnStarted(int code) {
  if (code == kStartOk) {
    running_ = true;
    if (pending_start_) {
      auto pending = std::move(pending_start_);
      pending->Success(flutter::EncodableValue(true));
    }
    return;
  }
  // The thread ends by itself after a failed start.
  if (thread_.joinable()) thread_.join();
  if (stop_event_ != nullptr) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }
  running_ = false;
  if (pending_start_) {
    auto pending = std::move(pending_start_);
    if (code == kStartUnsupported) {
      pending->Error("unsupported",
                     "Process loopback capture needs Windows 11 or "
                     "Windows 10 build 20348 or later.");
    } else {
      pending->Error("failed", "Process loopback capture could not start.");
    }
  }
}

void AudioLevelPlugin::OnWindows() {
  std::vector<Window> windows;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    windows.swap(queue_);
  }
  if (windows.empty() || !sink_) return;
  flutter::EncodableList ends;
  flutter::EncodableList levels;
  ends.reserve(windows.size());
  levels.reserve(windows.size());
  for (const Window& w : windows) {
    ends.emplace_back(w.end_us);
    levels.emplace_back(w.db);
  }
  flutter::EncodableMap batch;
  // Read on the same clock as the stamps, just before the batch leaves, so
  // the Dart side can tell how long ago each window was captured.
  batch[flutter::EncodableValue("nowUs")] = flutter::EncodableValue(NowUs());
  batch[flutter::EncodableValue("endUs")] = flutter::EncodableValue(ends);
  batch[flutter::EncodableValue("db")] = flutter::EncodableValue(levels);
  sink_->Success(flutter::EncodableValue(batch));
}

void AudioLevelPlugin::SendLost() {
  // The capture ended by itself (the device went away, say). Say so; Dart may
  // start it again.
  if (thread_.joinable()) thread_.join();
  if (stop_event_ != nullptr) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }
  running_ = false;
  if (sink_) {
    sink_->Error("capture_lost", "Audio capture ended.");
  }
}

void AudioLevelPlugin::CaptureMain(uint32_t generation) {
  // Runs on its own thread, in its own apartment. Every exit path reports
  // once (started-with-failure, or lost after a successful start) unless it
  // was asked to stop.
  const HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  IAudioClient* client = nullptr;
  IAudioCaptureClient* capture = nullptr;
  HANDLE sample_event = nullptr;
  bool started_reported = false;
  bool client_started = false;
  int failure = kStartFailed;

  auto stopped = [this] {
    return WaitForSingleObject(stop_event_, 0) == WAIT_OBJECT_0;
  };

  do {
    if (!BuildAtLeast(kMinBuild)) {
      failure = kStartUnsupported;
      break;
    }
    using ActivateFn = HRESULT(WINAPI*)(
        LPCWSTR, REFIID, PROPVARIANT*, IActivateAudioInterfaceCompletionHandler*,
        IActivateAudioInterfaceAsyncOperation**);
    HMODULE mmdevapi = LoadLibraryW(L"mmdevapi.dll");
    auto activate =
        mmdevapi == nullptr
            ? nullptr
            : reinterpret_cast<ActivateFn>(
                  GetProcAddress(mmdevapi, "ActivateAudioInterfaceAsync"));
    if (activate == nullptr) {
      failure = kStartUnsupported;
      break;
    }

    AUDIOCLIENT_ACTIVATION_PARAMS params = {};
    params.ActivationType = AUDIOCLIENT_ACTIVATION_TYPE_PROCESS_LOOPBACK;
    params.ProcessLoopbackParams.TargetProcessId = GetCurrentProcessId();
    params.ProcessLoopbackParams.ProcessLoopbackMode =
        PROCESS_LOOPBACK_MODE_INCLUDE_TARGET_PROCESS_TREE;
    PROPVARIANT variant = {};
    variant.vt = VT_BLOB;
    variant.blob.cbSize = sizeof(params);
    variant.blob.pBlobData = reinterpret_cast<BYTE*>(&params);

    auto* handler = new ActivationHandler();
    IActivateAudioInterfaceAsyncOperation* operation = nullptr;
    HRESULT hr = activate(VIRTUAL_AUDIO_DEVICE_PROCESS_LOOPBACK,
                          __uuidof(IAudioClient), &variant, handler,
                          &operation);
    if (FAILED(hr)) {
      handler->Release();
      break;
    }
    HANDLE waits[2] = {handler->done(), stop_event_};
    const DWORD waited =
        WaitForMultipleObjects(2, waits, FALSE, kActivateTimeoutMs);
    HRESULT activate_hr = E_FAIL;
    IUnknown* unknown = nullptr;
    if (waited == WAIT_OBJECT_0) {
      hr = operation->GetActivateResult(&activate_hr, &unknown);
      if (SUCCEEDED(hr) && SUCCEEDED(activate_hr) && unknown != nullptr) {
        unknown->QueryInterface(__uuidof(IAudioClient),
                                reinterpret_cast<void**>(&client));
      }
    }
    SafeRelease(unknown);
    SafeRelease(operation);
    handler->Release();
    if (client == nullptr) break;

    // Process loopback has no mix format to ask for, so the format is stated:
    // 32-bit float stereo at 48 kHz. AUTOCONVERTPCM lets the engine convert.
    WAVEFORMATEX format = {};
    format.wFormatTag = WAVE_FORMAT_IEEE_FLOAT;
    format.nChannels = kChannels;
    format.nSamplesPerSec = kSampleRate;
    format.wBitsPerSample = 32;
    format.nBlockAlign = kChannels * 4;
    format.nAvgBytesPerSec = kSampleRate * format.nBlockAlign;
    hr = client->Initialize(
        AUDCLNT_SHAREMODE_SHARED,
        AUDCLNT_STREAMFLAGS_LOOPBACK | AUDCLNT_STREAMFLAGS_EVENTCALLBACK |
            AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM |
            AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY,
        2000000, 0, &format, nullptr);
    if (FAILED(hr)) break;
    sample_event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (sample_event == nullptr) break;
    if (FAILED(client->SetEventHandle(sample_event))) break;
    if (FAILED(client->GetService(__uuidof(IAudioCaptureClient),
                                  reinterpret_cast<void**>(&capture)))) {
      break;
    }
    if (FAILED(client->Start())) break;
    client_started = true;

    if (stopped()) break;
    started_reported = true;
    PostToPlatform(generation, kMsgStarted, kStartOk);

    // ── Measuring ─────────────────────────────────────────────────────────
    SpeechMeter meter;
    std::vector<Window> pending;
    bool anchored = false;
    int64_t anchor_us = 0;       // Capture time of the frame counted as 0.
    int64_t frames_since = 0;    // Frames measured since the anchor.
    int64_t last_post_us = NowUs();
    bool lost = false;
    HANDLE loop_waits[2] = {stop_event_, sample_event};

    while (true) {
      const DWORD w = WaitForMultipleObjects(2, loop_waits, FALSE, 100);
      if (w == WAIT_OBJECT_0) break;

      // Also drained on a timeout: a quiet stretch may deliver no event.
      while (true) {
        UINT32 available = 0;
        hr = capture->GetNextPacketSize(&available);
        if (FAILED(hr)) {
          lost = true;
          break;
        }
        if (available == 0) break;
        BYTE* data = nullptr;
        UINT32 frames = 0;
        DWORD flags = 0;
        UINT64 qpc = 0;
        hr = capture->GetBuffer(&data, &frames, &flags, nullptr, &qpc);
        if (FAILED(hr)) {
          lost = true;
          break;
        }
        const bool silent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0;
        const bool stamp_ok =
            qpc != 0 && (flags & AUDCLNT_BUFFERFLAGS_TIMESTAMP_ERROR) == 0;
        // qpc is in 100 ns units on the QueryPerformanceCounter clock.
        const int64_t start_us = stamp_ok ? static_cast<int64_t>(qpc / 10) : 0;
        const int64_t expected_us =
            anchor_us + frames_since * 1000000 / kSampleRate;
        const bool jumped =
            !anchored || (flags & AUDCLNT_BUFFERFLAGS_DATA_DISCONTINUITY) ||
            (stamp_ok && std::llabs(start_us - expected_us) > kGapToleranceUs);
        if (jumped) {
          anchored = true;
          anchor_us = stamp_ok ? start_us
                               : NowUs() - int64_t{frames} * 1000000 /
                                               kSampleRate;
          frames_since = 0;
          meter.Reset();
        }
        const float* in = reinterpret_cast<const float*>(data);
        for (UINT32 i = 0; i < frames; ++i) {
          double x = 0.0;
          if (!silent && in != nullptr) {
            const double l = in[i * kChannels];
            const double r = in[i * kChannels + 1];
            if (std::isfinite(l) && std::isfinite(r)) x = 0.5 * (l + r);
          }
          ++frames_since;
          double db = 0.0;
          if (meter.Add(x, &db)) {
            pending.push_back(
                {anchor_us + frames_since * 1000000 / kSampleRate, db});
          }
        }
        capture->ReleaseBuffer(frames);
      }
      if (lost) break;

      if (!pending.empty() && NowUs() - last_post_us >= kBatchEveryUs) {
        {
          std::lock_guard<std::mutex> lock(mutex_);
          queue_.insert(queue_.end(), pending.begin(), pending.end());
          if (queue_.size() > kMaxQueued) {
            queue_.erase(queue_.begin(),
                         queue_.begin() + (queue_.size() - kMaxQueued));
          }
        }
        pending.clear();
        last_post_us = NowUs();
        PostToPlatform(generation, kMsgWindows, 0);
      }
    }
    if (lost && !stopped()) PostToPlatform(generation, kMsgLost, 0);
    failure = kStartOk;
  } while (false);

  if (client != nullptr && client_started) client->Stop();
  SafeRelease(capture);
  SafeRelease(client);
  if (sample_event != nullptr) CloseHandle(sample_event);
  if (SUCCEEDED(com)) CoUninitialize();

  if (!started_reported && !stopped()) PostToPlatform(generation, kMsgStarted, failure);
}
