//
//  RouteActivityWidgetBundle.swift
//  RouteActivityWidget
//
//  Created by JuanRa Fernandez on 12/12/25.
//

import WidgetKit
import SwiftUI

@main
struct RouteActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Solo incluimos el Live Activity, no widget estático
        RouteActivityLiveActivity()
    }
}
