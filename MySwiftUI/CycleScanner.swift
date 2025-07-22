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
    /// item大小
    var itemSize: CGSize = .zero
    /// item间距
    var itemSpacing: CGFloat = 0
    /// 滚动间隔
    var interval: Double = 3
    /// item数量
    var itemCount: Int  = 0
    /// 滚动方向
    var direction: Axis.Set = .horizontal
    
}

struct MyCycleScanner<Content: View>: View {

    let content: (Int) -> Content
    
    @State private var offset: CGFloat = 0
    
    @State private var currentIndex: Int = 0
    
    @State private var isDragging: Bool = false

    @Binding var curIndex: Int
    
    @State private var timer: Timer?
    
    private var config = CycleScannerConfig()
    
    init(direction: Axis.Set = .horizontal,
         itemSize: CGSize = .zero,
         itemSpacing: CGFloat = 0.0,
         itemCount: Int = 0,
         curIndex: Binding<Int> = .constant(0), @ViewBuilder content: @escaping (Int) -> Content) {
        
        self.config = CycleScannerConfig()
        self._curIndex = curIndex
        self.content = content
        config.direction = direction
        config.itemSize = itemSize
        config.itemSpacing = itemSpacing
        config.itemCount = itemCount
    }
    
    init(config: CycleScannerConfig, curIndex: Binding<Int> = .constant(0), @ViewBuilder content: @escaping (Int) -> Content) {
        _curIndex = curIndex
        self.config = config
        self.content = content
    }
    
    var body: some View {
        let direction = config.direction
        let itemSize = config.itemSize
        let itemSpacing = config.itemSpacing
        let itemCount = config.itemCount
        
        let isHorizontal = direction == .horizontal
        let scrollStep = isHorizontal ? itemSize.width: itemSize.height
        let totalLength = (scrollStep + itemSpacing) * CGFloat(itemCount) - itemSpacing
        let scrollH = isHorizontal ? itemSize.height: totalLength
        let scrollW = isHorizontal ? totalLength: itemSize.width
        let offsetAbs = (CGFloat(currentIndex) * (scrollStep + itemSpacing))
        let offsetX = isHorizontal ? -offsetAbs: 0
        let offsetY = isHorizontal ? 0: -offsetAbs
        let dragX = isHorizontal ? offset: 0
        let dragY = isHorizontal ? 0: offset
        GeometryReader() { geo in
            Group {
                if direction == .horizontal {
                    HStack(alignment: .center, spacing: itemSpacing) { itemBuild() }
                } else {
                    VStack(alignment: .center, spacing: itemSpacing) { itemBuild() }
                }
            }.frame(width: scrollW, height: scrollH, alignment: .center)
        }
        .offset(x: offsetX + dragX, y: offsetY + dragY)
        .onAppear(perform: bodyAppear)
        .onDisappear(perform: stopTimer)
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    offset = isHorizontal ? value.translation.width: value.translation.height
                }
                .onEnded { value in
                    let scrollOffset = isHorizontal ? value.predictedEndTranslation.width: value.predictedEndTranslation.height
                    let newIndex = Int(round(scrollOffset / scrollStep))
                    
                    withAnimation(.spring()) {
                        // 限制索引范围
                        currentIndex = max(0, min(currentIndex - newIndex, itemCount - 1))
                        offset = 0
                    } completion: {
                        updateColorTitle()
                        isDragging = false
                    }
                }
        )
        
    }
    
    @ViewBuilder private func itemBuild() -> some View {
        let itemCount = config.itemCount
        let itemSize = config.itemSize
        ForEach(0..<itemCount, id: \.self) { index in
            content(index)
                .frame(width: itemSize.width, height: itemSize.height, alignment: .center)
        }
    }
    
    private func bodyAppear() {
        self.updateColorTitle()
        self.startTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: config.interval, repeats: true) {  timer in
            guard config.itemCount > 1 && !isDragging else { return }
            let index = (self.currentIndex + 1) % config.itemCount
            withAnimation(index == 0 ? .none : .default) {
                self.currentIndex = index
            } completion: {
                self.updateColorTitle()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateColorTitle() {
        curIndex = self.currentIndex
    }
    
}
