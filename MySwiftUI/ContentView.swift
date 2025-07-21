//
//  ContentView.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MyCycleScanner(pageCount: 4){  index  in
            RoundedRectangle(cornerRadius: 10)
                .fill(colors[index])
                .overlay(Text("Page \(index + 1)")
                    .font(.title).bold()
                    .foregroundColor(.blue))
                .shadow(radius: 5)
                
        }
        .config(itemSize: CGSize(width: 40, height: 20), itemSpacing: 0)
        .frame(width: 120, height: 80)
        .border(.blue)
    }
    
    private var colors: [Color] = [.blue, .green, .orange, .purple]
}

