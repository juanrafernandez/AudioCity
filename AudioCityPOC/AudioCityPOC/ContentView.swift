//
//  ContentView.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RouteViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let route = viewModel.currentRoute {
                RouteDetailView(viewModel: viewModel, route: route)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error, onRetry: {
                    viewModel.loadRoute()
                })
            } else {
                ErrorView(message: "No se pudo cargar la ruta", onRetry: {
                    viewModel.loadRoute()
                })
            }
        }
        .onAppear {
            viewModel.loadRoute()
        }
    }
}

#Preview {
    ContentView()
}
