#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  pointer_lock_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "reactionpro/pointer_lock",
          &flutter::StandardMethodCodec::GetInstance());
  pointer_lock_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "lock") {
          result->Success(flutter::EncodableValue(SetPointerLock(true)));
          return;
        }
        if (call.method_name() == "unlock") {
          SetPointerLock(false);
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  SetPointerLock(false);
  pointer_lock_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_INPUT && pointer_locked_) {
    HandleRawMouseInput(lparam);
  }
  if (message == WM_ACTIVATE && LOWORD(wparam) == WA_INACTIVE &&
      pointer_locked_) {
    SetPointerLock(false);
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

bool FlutterWindow::SetPointerLock(bool locked) {
  if (!locked) {
    if (!pointer_locked_) {
      return true;
    }
    ClipCursor(nullptr);
    pointer_locked_ = false;
    NotifyPointerLockChanged();
    return true;
  }

  if (pointer_locked_) {
    return true;
  }

  const HWND window = GetHandle();
  if (window == nullptr) {
    return false;
  }

  RAWINPUTDEVICE mouse_device{};
  mouse_device.usUsagePage = 0x01;
  mouse_device.usUsage = 0x02;
  mouse_device.dwFlags = RIDEV_INPUTSINK;
  mouse_device.hwndTarget = window;
  if (!RegisterRawInputDevices(&mouse_device, 1, sizeof(mouse_device))) {
    return false;
  }

  RECT client_rect{};
  if (!GetClientRect(window, &client_rect)) {
    return false;
  }
  POINT center{
      (client_rect.left + client_rect.right) / 2,
      (client_rect.top + client_rect.bottom) / 2,
  };
  if (!ClientToScreen(window, &center)) {
    return false;
  }

  RECT lock_rect{center.x, center.y, center.x + 1, center.y + 1};
  if (!ClipCursor(&lock_rect)) {
    return false;
  }
  SetCursorPos(center.x, center.y);
  pointer_locked_ = true;
  NotifyPointerLockChanged();
  return true;
}

void FlutterWindow::HandleRawMouseInput(LPARAM lparam) {
  RAWINPUT input{};
  UINT input_size = sizeof(input);
  if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lparam), RID_INPUT, &input,
                      &input_size, sizeof(RAWINPUTHEADER)) ==
      static_cast<UINT>(-1)) {
    return;
  }
  if (input.header.dwType != RIM_TYPEMOUSE ||
      (input.data.mouse.usFlags & MOUSE_MOVE_ABSOLUTE) != 0) {
    return;
  }

  const LONG movement_x = input.data.mouse.lLastX;
  const LONG movement_y = input.data.mouse.lLastY;
  if ((movement_x == 0 && movement_y == 0) ||
      pointer_lock_channel_ == nullptr) {
    return;
  }

  flutter::EncodableList movement{
      flutter::EncodableValue(static_cast<double>(movement_x)),
      flutter::EncodableValue(static_cast<double>(movement_y)),
  };
  pointer_lock_channel_->InvokeMethod(
      "pointerMove",
      std::make_unique<flutter::EncodableValue>(movement));
}

void FlutterWindow::NotifyPointerLockChanged() {
  if (pointer_lock_channel_ == nullptr) {
    return;
  }
  pointer_lock_channel_->InvokeMethod(
      "lockChanged",
      std::make_unique<flutter::EncodableValue>(pointer_locked_));
}
