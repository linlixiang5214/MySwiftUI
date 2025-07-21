//
//  File.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

enum CycleScannerDirection: String {
    case vertical
    case horizontal
}

struct CycleScannerConfig {
    var itemSize: CGSize = CGSize(width: 30, height: 30)
    var itemSpacing: CGFloat = 0
    var animationDuration: Double = 0.3
    var backgroundColor: Color = .clear
}

struct MyCycleScanner<Content: View>: View {
    
    let pageCount: Int
    
    let content: (Int) -> Content
    
    @State private var offset: CGFloat = 0
    
    @State private var currentIndex: Int = 0
    
    @State private var direction: Axis.Set = .horizontal
    /// item 大小
    private var itemSize: CGSize = CGSize(width: 30, height: 30)
    /// item 间距
    private var itemSpacing: CGFloat = 0
    
    init(pageCount: Int, @ViewBuilder content: @escaping (Int) -> Content) {
        self.pageCount = pageCount
        self.content = content
    }
    
    var body: some View {
        Text("itemSize: \(itemSize)").font(.system(size: 8))
        let _ = print("body update")
        ScrollView(direction) {
            let totalWidth = (itemSize.width + itemSpacing) * CGFloat(pageCount)
            HStack(alignment: .center, spacing: itemSpacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    content(index)
                        .frame(width: itemSize.width, height: itemSize.height, alignment: .center)
                }
            }
            .frame(width: totalWidth)
        }
        
    }
    
    
    func config(itemSize: CGSize = .zero, itemSpacing: CGFloat = 0) -> some View {
        self.itemSize = itemSize
        self.itemSpacing = itemSpacing
        
        print("config: \(itemSize)")
        return self.transformEnvironment(\.self) { _ in }
    }
    
    
}
