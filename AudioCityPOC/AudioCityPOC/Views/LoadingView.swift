//
//  LoadingView.swift
//  AudioCityPOC
//
//  Vista de carga
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Cargando ruta...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Conectando con Firebase")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    LoadingView()
}
