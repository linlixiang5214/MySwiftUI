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
    
    @State private var curIndex: Int = 0
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 10) {
            Text("当前的颜色是: \(colorModel.colors[curIndex].description)").frame(height: 40)
            
            let itemSize = CGSize(width: 220, height: 140)
            MyCycleScanner(itemSize: itemSize, itemSpacing: 0, itemCount:colorModel.colors.count, curIndex: $curIndex){  index  in
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorModel.colors[index])
                    .overlay(Text("Page \(index + 1)")
                        .font(.title).bold()
                        .foregroundColor(.white))
            }
            .frame(width: 220, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
            }
        
            MyCycleScanner(config: getVerticalConfig()){  index  in
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorModel.colors[index])
                    .overlay(Text("Page \(index + 1)")
                        .font(.title).bold()
                        .foregroundColor(.white))
            }
            .frame(width: 220, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
            }
        }
        
 
    }
    
    private func getVerticalConfig() -> CycleScannerConfig {
        var config = CycleScannerConfig()
        config.direction = .vertical
        config.itemSize = CGSize(width: 220, height: 140)
        config.itemCount = colorModel.colors.count
        config.itemSpacing = 0
        return config
    }

    
}

