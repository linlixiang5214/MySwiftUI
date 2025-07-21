//
//  ContentView.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

struct ContentView: View {
    
    private var colors: [Color] = [.blue, .green, .orange, .purple, .pink, .brown]
    
    @State private var curColorStr: String = "0"
    
    var body: some View {
        Text("当前的颜色是: \(curColorStr)")
        
        let itemSize = CGSize(width: 220, height: 140)
        MyCycleScanner(pageCount: colors.count, itemSize: itemSize, itemSpacing: 0, curColorStr: $curColorStr){  index  in
            RoundedRectangle(cornerRadius: 20)
                .fill(colors[index])
                .overlay(Text("Page \(index + 1)")
                    .font(.title).bold()
                    .foregroundColor(.white))
                
                
                
        }
        .frame(width: 220, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 1)
        }
        .environment(colors)
    }

    
}

