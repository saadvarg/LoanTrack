import SwiftUI
import PDFKit

struct PDFViewer: View {
    let data: Data
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            PDFKitView(data: data)
                .navigationTitle("Lead Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: data,
                            preview: SharePreview(
                                "Lead Report",
                                image: Image(systemName: "doc.fill")
                            )
                        )
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        configure(pdfView)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        configure(pdfView)
    }

    private func configure(_ pdfView: PDFView) {
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // ✅ SAFETY: validate PDF
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        } else {
            print("❌ Invalid PDF data")

            // 🔥 Debug: show what backend actually returned
            if let text = String(data: data, encoding: .utf8) {
                print("Response was:\n\(text)")
            }
        }
    }
}
