//
//  ContentView.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

class SourceModel: ObservableObject {
    @Published var colors: [Color] = [.blue, .green, .orange, .purple, .pink, .brown]
}

struct ContentView: View {
    
    private var colorModel = SourceModel()
    
    @State private var curColorStr: String = "0"
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 10) {
            Text("当前的颜色是: \(curColorStr)").frame(height: 40)
            
            let itemSize = CGSize(width: 220, height: 140)
            MyCycleScanner(itemSize: itemSize, itemSpacing: 0, curColorStr: $curColorStr){  index  in
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorModel.colors[index])
                    .overlay(Text("Page \(index + 1)")
                        .font(.title).bold()
                        .foregroundColor(.white))
            }
            .frame(width: 220, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
            }
            .environmentObject(colorModel)
            
            MyCycleScanner(direction: .vertical, itemSize: itemSize, itemSpacing: 0, curColorStr: $curColorStr){  index  in
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorModel.colors[index])
                    .overlay(Text("Page \(index + 1)")
                        .font(.title).bold()
                        .foregroundColor(.white))
            }
            .frame(width: 220, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
            }
            .environmentObject(colorModel)
        }
        
 
    }

    
}

