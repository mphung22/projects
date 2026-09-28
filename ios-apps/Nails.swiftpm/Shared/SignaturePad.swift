// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import PencilKit
import SwiftUI

/// Finger / Apple Pencil signature box. Stores the signature as PNG data.
struct SignaturePad: View {
    @Environment(\.languageMode) private var mode
    let title: L
    @Binding var signature: Data?
    var required = false
    @State private var canvasID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                FieldLabel(title: title, required: required)
                Spacer()
                Button(role: .destructive) {
                    signature = nil
                    canvasID = UUID()
                } label: {
                    Label(L("Ký lại", "Clear").text(mode), systemImage: "arrow.counterclockwise")
                }
                .disabled(signature == nil)
            }

            SignatureCanvas(signature: $signature)
                .id(canvasID)
                .frame(height: 200)
                .background {
                    ZStack(alignment: .bottomLeading) {
                        Color.white
                        HStack(alignment: .bottom, spacing: 8) {
                            Image(systemName: "xmark").foregroundStyle(.secondary)
                            Rectangle().fill(Color.secondary.opacity(0.5)).frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 44)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(signature == nil && required ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 1.5)
                )

            Text(L("Ký bằng ngón tay hoặc Apple Pencil", "Sign with your finger or Apple Pencil").text(mode))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SignatureCanvas: UIViewRepresentable {
    @Binding var signature: Data?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.bounces = false
        // Keep ink black even if the iPad is in dark mode.
        canvas.overrideUserInterfaceStyle = .light
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignatureCanvas

        init(_ parent: SignatureCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            guard !drawing.strokes.isEmpty else {
                parent.signature = nil
                return
            }
            var image = UIImage()
            UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                image = drawing.image(from: drawing.bounds.insetBy(dx: -12, dy: -12), scale: 2)
            }
            parent.signature = image.pngData()
        }
    }
}
