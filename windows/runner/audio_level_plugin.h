#ifndef RUNNER_AUDIO_LEVEL_PLUGIN_H_
#define RUNNER_AUDIO_LEVEL_PLUGIN_H_

#include <flutter/binary_messenger.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <windows.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

// How loud the speech band of this app's own audio output is, one figure per
// tenth of a second, for the subtitle auto-sync (the Windows counterpart of
// Media3's AudioLevelMeter).
//
// It listens with WASAPI process loopback: only what this process plays is
// captured, a copy taken inside the audio engine, so what the viewer hears is
// never touched. Nothing happens until Dart calls `start`; `stop`, the Dart
// side cancelling its listener, or the window closing all end it.
//
// Threads: the channel handlers and the EventSink live on the platform thread.
// Capture runs on its own thread and hands finished windows over through a
// queue, with a PostMessage to a hidden message-only window so the platform
// thread is the one that calls the sink.
class AudioLevelPlugin {
 public:
  explicit AudioLevelPlugin(flutter::BinaryMessenger* messenger);
  ~AudioLevelPlugin();

  AudioLevelPlugin(const AudioLevelPlugin&) = delete;
  AudioLevelPlugin& operator=(const AudioLevelPlugin&) = delete;

 private:
  using Result = flutter::MethodResult<flutter::EncodableValue>;

  struct Window {
    int64_t end_us;  // QPC time the window's last sample was captured.
    double db;
  };

  void HandleCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                  std::unique_ptr<Result> result);
  void Start(std::unique_ptr<Result> result);
  void Stop();

  // Platform thread, from the message window.
  void OnStarted(int code);
  void OnWindows();
  void SendLost();

  void CaptureMain(uint32_t generation);
  void PostToPlatform(uint32_t generation, UINT message, WPARAM wparam);
  bool EnsureMessageWindow();

  static LRESULT CALLBACK MessageProc(HWND hwnd, UINT message, WPARAM wparam,
                                      LPARAM lparam);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;

  HWND message_window_ = nullptr;
  std::thread thread_;
  HANDLE stop_event_ = nullptr;

  // Bumped by every Start/Stop so a late message from an old capture is
  // ignored.
  std::atomic<uint32_t> generation_{0};
  bool running_ = false;
  // The pending `start` call, answered when the capture thread reports.
  std::unique_ptr<Result> pending_start_;

  std::mutex mutex_;
  std::vector<Window> queue_;
  int start_code_ = 0;
};

#endif  // RUNNER_AUDIO_LEVEL_PLUGIN_H_
