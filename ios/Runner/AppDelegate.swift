import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
                         UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  private var imagePickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Timezone channel
    let tzReg = engineBridge.pluginRegistry.registrar(forPlugin: "SmakolistTimezonePlugin")!
    let tzChannel = FlutterMethodChannel(
      name: "com.texapp.smakolist/timezone",
      binaryMessenger: tzReg.messenger()
    )
    tzChannel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result(TimeZone.current.identifier)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Native image picker channel (bypasses PHPickerViewController HEIC bugs)
    let pickerReg = engineBridge.pluginRegistry.registrar(forPlugin: "SmakolistImagePickerPlugin")!
    let pickerChannel = FlutterMethodChannel(
      name: "com.texapp.smakolist/image_picker",
      binaryMessenger: pickerReg.messenger()
    )
    pickerChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "pickImage" {
        let sourceStr = (call.arguments as? String) ?? "gallery"
        let source: UIImagePickerController.SourceType =
          sourceStr == "camera" ? .camera : .photoLibrary
        self.presentImagePicker(source: source, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func topViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = keyWindow?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  private func presentImagePicker(
    source: UIImagePickerController.SourceType,
    result: @escaping FlutterResult
  ) {
    guard UIImagePickerController.isSourceTypeAvailable(source) else {
      result(FlutterError(code: "unavailable", message: "Source not available", details: nil))
      return
    }
    imagePickerResult = result
    let picker = UIImagePickerController()
    picker.sourceType = source
    picker.delegate = self
    picker.allowsEditing = false
    DispatchQueue.main.async {
      self.topViewController()?.present(picker, animated: true)
    }
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage else {
      imagePickerResult?(FlutterError(code: "no_image", message: "No image", details: nil))
      imagePickerResult = nil
      return
    }
    let tempDir = NSTemporaryDirectory()
    let fileName = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
    let filePath = (tempDir as NSString).appendingPathComponent(fileName)
    if let data = image.jpegData(compressionQuality: 0.9) {
      do {
        try data.write(to: URL(fileURLWithPath: filePath))
        imagePickerResult?(filePath)
      } catch {
        imagePickerResult?(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
      }
    } else {
      imagePickerResult?(FlutterError(code: "jpeg_failed", message: "Cannot encode JPEG", details: nil))
    }
    imagePickerResult = nil
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    imagePickerResult?(nil)
    imagePickerResult = nil
  }
}
