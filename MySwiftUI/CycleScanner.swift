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
    
    @Environment var color: [Color]
    
    let pageCount: Int
    
    let content: (Int) -> Content
    
    @State private var offset: CGFloat = 0
    
    @State private var currentIndex: Int = 0
    
    @State private var direction: Axis.Set = .horizontal
    
    @Binding var curStr: String
    /// item 大小
    private var itemSize: CGSize = .zero
    /// item 间距
    private var itemSpacing: CGFloat = 0
    
    @State private var timer: Timer?
    
    init(pageCount: Int, itemSize: CGSize, itemSpacing: CGFloat, curColorStr: Binding<String>, @ViewBuilder content: @escaping (Int) -> Content) {
        self._curStr = curColorStr
        self.pageCount = pageCount
        self.content = content
        self.itemSize = itemSize
        self.itemSpacing = itemSpacing
    }
    
    var body: some View {
        Text("itemSize: \(itemSize)").font(.system(size: 10)).frame(height: 20)
        let _ = print("body update")
        
        let scrollStep = direction == .horizontal ? itemSize.width: itemSize.height
        let totalLength = (scrollStep + itemSpacing) * CGFloat(pageCount) - itemSpacing
        
        GeometryReader() { geo in
            if direction == .horizontal {
                HStack(alignment: .center, spacing: itemSpacing) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        content(index)
                            .frame(width: itemSize.width, height: itemSize.height, alignment: .center)
                    }
                }
                .frame(width: totalLength)
            } else {
                VStack(alignment: .center, spacing: itemSpacing) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        content(index)
                            .frame(width: itemSize.width, height: itemSize.height, alignment: .center)
                    }
                }
                .frame(height: totalLength)
            }
        }
        .offset(x: -(CGFloat(currentIndex) * (itemSize.width + itemSpacing)))
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .gesture(
            DragGesture()
                .onChanged { value in
                    stopTimer()
                }
                .onEnded { value in
                    let translation = value.translation
                    let offset = direction == .horizontal ? translation.width : translation.height
                    let itemSize = direction == .horizontal ? itemSize.width + itemSpacing : itemSize.height + itemSpacing
                    
                    // 判断滑动方向
                    if abs(offset) > itemSize / 2 {
                        let newIndex = offset < 0 ? min(currentIndex + 1, pageCount - 1) : max(currentIndex - 1, 0)
                        currentIndex = newIndex
                    }
                    startTimer()
                }
        )
        
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {  timer in
            let index = (self.currentIndex + 1) % self.pageCount
            withAnimation(index == 0 ? .none : .default) {
                self.currentIndex = index
            }
            
            print("timer invoke: \(index), pageCount:\(self.pageCount)")
            self.curStr = "\(self.currentIndex)"
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
