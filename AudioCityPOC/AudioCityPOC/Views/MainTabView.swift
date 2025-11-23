//
//  MainTabView.swift
//  AudioCityPOC
//
//  Vista principal con navegación por tabs
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Explorar mapa
            MapExploreView()
                .tabItem {
                    Label("Explorar", systemImage: "map.fill")
                }
                .tag(0)

            // Tab 2: Rutas
            RoutesListView()
                .tabItem {
                    Label("Rutas", systemImage: "list.bullet")
                }
                .tag(1)

            // Tab 3: Perfil
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
