import AVFoundation
import SwiftUI

struct QRScannerView: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var manualCode = ""
    @State private var showManualEntry = false
    @State private var cameraPermissionDenied = false

    var body: some View {
        NavigationStack {
            VStack {
                if showManualEntry || cameraPermissionDenied {
                    manualEntryView
                } else {
                    cameraView
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(showManualEntry ? "Camera" : "Manual") {
                        if !cameraPermissionDenied {
                            showManualEntry.toggle()
                        }
                    }
                    .disabled(cameraPermissionDenied && !showManualEntry)
                }
            }
        }
    }

    private var cameraView: some View {
        VStack(spacing: 20) {
            #if targetEnvironment(simulator)
            simulatorPlaceholder
            #else
            CameraPreviewView { code in
                onCodeScanned(code)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
            #endif
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    #if targetEnvironment(simulator)
    private var simulatorPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .aspectRatio(1, contentMode: .fit)
                .padding()

            VStack {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.5))
                Text("Camera not available in simulator")
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top)
                Button("Enter Code Manually") {
                    showManualEntry = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
    }
    #endif

    private var manualEntryView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Enter QR Code")
                .font(.title2)

            TextField("QR Code / Access Code", text: $manualCode)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            Button("Submit") {
                guard !manualCode.isEmpty else { return }
                onCodeScanned(manualCode)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(manualCode.isEmpty)

            Spacer()
        }
    }

    private func checkCameraPermission() {
        #if targetEnvironment(simulator)
            showManualEntry = true
        #else
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    Task { @MainActor in
                        if !granted { cameraPermissionDenied = true }
                    }
                }
            default:
                cameraPermissionDenied = true
            }
        #endif
    }
}

// MARK: - Live Camera Preview with QR Detection

#if !targetEnvironment(simulator)
struct CameraPreviewView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let session = AVCaptureSession()
        context.coordinator.session = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            return view
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue
            else { return }

            hasScanned = true
            session?.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned(value)
        }
    }
}
#endif
