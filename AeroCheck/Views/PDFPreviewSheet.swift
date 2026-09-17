//
//  PDFPreviewSheet.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// Sheet displaying high-resolution generated audit PDF with native iOS sharing.
public struct PDFPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    public let pdfData: Data?

    public init(pdfData: Data?) {
        self.pdfData = pdfData
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let data = pdfData, let document = PDFDocument(data: data) {
                    PDFKitRepresentedView(document: document)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: DesignTokens.spaceM) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(DesignTokens.verdictCaution)
                        Text("Unable to render PDF document.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(DesignTokens.canvasBackground)
            .navigationTitle("FAA Part 107 Audit PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DesignTokens.aeroBlue)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let data = pdfData {
                        ShareLink(
                            item: PDFShareItem(pdfData: data, filename: "AeroCheck_Part107_RAM.pdf"),
                            preview: SharePreview("AeroCheck Part 107 Compliance Audit", image: Image(systemName: "doc.text.fill"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(DesignTokens.aeroBlue)
                        }
                    }
                }
            }
        }
    }
}

/// SwiftUI wrapper around UIKit's native PDFView for smooth zooming and viewing.
struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1.0)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

/// Transferable item for modern iOS ShareLink export.
struct PDFShareItem: Transferable {
    let pdfData: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            item.pdfData
        }
        .suggestedFileName { item in
            item.filename
        }
    }
}
