//
//  restaurantFinderApp.swift
//  restaurantFinder
//
//  Created by Aayush Bharti on 10/28/25.
//

import SwiftUI
import SwiftData

@main
struct restaurantFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [User.self, restaurantInfo.self])
    }
}
