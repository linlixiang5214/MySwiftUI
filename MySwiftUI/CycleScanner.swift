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
    
    @EnvironmentObject var colorModel: SourceModel
    
    private var pageCount: Int {
        return colorModel.colors.count
    }
    
    let content: (Int) -> Content
    
    @State private var offset: CGFloat = 0
    
    @State private var currentIndex: Int = 0
    
    @Binding var curStr: String
    
    private var direction: Axis.Set = .horizontal
    /// item 大小
    private var itemSize: CGSize = .zero
    /// item 间距
    private var itemSpacing: CGFloat = 0
    
    @State private var timer: Timer?
    
    init(direction: Axis.Set = .horizontal, itemSize: CGSize, itemSpacing: CGFloat, curColorStr: Binding<String>, @ViewBuilder content: @escaping (Int) -> Content) {
        self._curStr = curColorStr
        self.content = content
        self.itemSize = itemSize
        self.itemSpacing = itemSpacing
        self.direction = direction
    }
    
    var body: some View {
        let _ = print("body update:\(direction.rawValue)")
        let isHorizontal = direction == .horizontal
        let scrollStep = isHorizontal ? itemSize.width: itemSize.height
        let totalLength = (scrollStep + itemSpacing) * CGFloat(pageCount) - itemSpacing
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
        .offset(x: offsetX, y: offsetY)
        .offset(x: dragX, y: dragY)
        .onAppear(perform: bodyAppear)
        .onDisappear(perform: stopTimer)
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    stopTimer()
                    offset = value.translation.width
                }
                .onEnded { value in
                    let newIndex = Int(round(value.predictedEndTranslation.width / scrollStep))
                    
                    withAnimation(.spring()) {
                        // 限制索引范围
                        currentIndex = max(0, min(currentIndex - newIndex, pageCount - 1))
                        offset = 0
                    } completion: {
                        updateColorTitle()
                        startTimer()
                    }
                }
        )
        
    }
    
    @ViewBuilder private func itemBuild() -> some View {
        ForEach(0..<pageCount, id: \.self) { index in
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
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {  timer in
            let index = (self.currentIndex + 1) % self.pageCount
            withAnimation(index == 0 ? .none : .default) {
                self.currentIndex = index
            }
            
            print("timer invoke: \(index), pageCount:\(self.pageCount)")
            updateColorTitle()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateColorTitle() {
        curStr = "\($colorModel.colors[currentIndex].wrappedValue)"
    }
    
}
