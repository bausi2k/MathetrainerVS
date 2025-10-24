//
//  ContentView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // Ein NavigationStack ermöglicht es uns, zwischen Bildschirmen
        // hin- und herzuwechseln (z. B. von "Start" zu "Einstellungen").
        NavigationStack {
            // Wir zeigen als Erstes unseren StartView an.
            StartView()
        }
    }
}
