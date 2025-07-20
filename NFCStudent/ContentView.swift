//
//  ContentView.swift
//  NFCStudent
//
//  Created by Yusuke Mizuno on 2025/07/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var nfcManager = NFCManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("NFC Reader")
                .font(.title)
                .padding()

            Button(action: {
                nfcManager.beginSession()
            }) {
                Text("Scan")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text(nfcManager.message)
                .padding()
                .foregroundColor(.gray)
            
            Text(nfcManager.result.dropFirst(2).dropLast(2))
                .font(.title2)
                .padding()
        }
        .padding()
    }
}
