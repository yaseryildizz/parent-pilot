//
//  ContentView.swift
//  ParentPilot
//
//  Created by Yaser on 04/09/2026.
//

import SwiftUI

struct ContentView: View {
    let viewModel: DocumentsViewModel

    var body: some View { DocumentsView(viewModel: viewModel) }
}

#if DEBUG
    #Preview {
        let service = PreviewDocumentService()
        let configuration = AppConfiguration(environment: .development)
        ContentView(
            viewModel: DocumentsViewModel(
                documentService: service,
                documentValidator: DocumentValidator(
                    maximumUploadBytes: configuration.maximumDocumentUploadBytes
                ),
                processingMonitor: DocumentProcessingMonitor(documentService: service)
            )
        )
    }
#endif
