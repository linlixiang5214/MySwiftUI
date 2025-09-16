//
//  ContentView.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

public let testRegionName = "mainView"

struct ContentView: View {
    
    @StateObject private var model = testModel()
    
    @State private var curIndex: Int = 0
    
    var body: some View {
        
        VStack(spacing: 10) {
            
            VStack {
                Spacer().frame(height: 30)
                Text("画布")
                    .foregroundStyle(.orange.opacity(0.6))
                Spacer()
                HStack() {
                    Text("命名空间: \(model.nameSpace)\(model.nameSpace.isEmpty ? "(默认空字符串)": "")")
                        .foregroundStyle(.red.opacity(0.8))
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("展示模式: \(model.presentMode)")
                        .foregroundStyle(.red.opacity(0.8))
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 12)

                Spacer().frame(height: 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .background(.yellow.opacity(0.2))
            .enableDynamicViewInjection(in: testRegionName)
            .clipped()
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .center, spacing: 6) {
                    Text("code & tip")
                        .foregroundStyle(.gray)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("\(model.codeStr)")
                        .foregroundStyle(.purple)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(3)
                        .frame(height: 60)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(.yellow.opacity(0.4))
            
            Spacer().frame(height: 10)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 25) {
                
                Button {
                    model.changeMode()
                } label: {
                    Text("改变弹出模式")
                }
                Button {
                    model.changeName()
                } label: {
                    Text("改变命名空间")
                }
                Button {
                    model.addView()
                } label: {
                    Text("添加普通视图")
                }
                Button {
                    model.dimissView()
                } label: {
                    Text("移除普通视图")
                }
                
                Button {
                    model.startTimer()
                } label: {
                    Text("模拟通知排队(Queue)")
                }
                Button {
                    model.stopTimer()
                } label: {
                    Text("停止模拟排队(Queue)")
                }
                Button {
                    model.dismissQueue()
                } label: {
                    Text("清空排队视图(Queue)")
                }
                Button {
                    model.showMoreQueues()
                } label: {
                    Text("\(model.showMoreQueue ? "关闭": "展示")多个排队(Queue)")
                }
            }
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(.yellow.opacity(0.1))
    }
    
}

public class testModel: ObservableObject {
    
    let animation = DynamicViewQueue(duration: 3, axis: .horizontal(orth: 250), inRegion: testRegionName)
    
    let animation1 = DynamicViewQueue(duration: 1, axis: .horizontal(orth: 100), inRegion: testRegionName)
    
    var animation2 = DynamicViewQueue(duration: 5, axis: .horizontal(orth: 200), inRegion: testRegionName)
    
    @Published var presentMode: DynamicViewRegionControl.PresentMode = .replace
    
    @Published var codeStr: String = ""
    
    @Published var nameSpace: String = ""
    
    @Published var showMoreQueue: Bool = false
    
    private let width = UIScreen.main.bounds.width
    
    private let height = UIScreen.main.bounds.height
    
    private var timer: Timer?
    
    private var count: Int = 0
    
    private var stackPosition: CGPoint = CGPoint(x: 100, y: 100)
    
    func changeName() {
        let names = ["", "name-1", "name-2", "name-3"]
        let index = ((names.firstIndex(of: nameSpace) ?? 0) + 1) % names.count
        nameSpace = names[index]
    }
    
    func changeMode() {
        presentMode = (presentMode == .replace ? .stack: .replace)
        codeStr = "changeMode to: \(presentMode)"
    }
    
    func addView() {
        if presentMode == .stack {
            var bgColor: Color = if nameSpace == "name-1" { .blue }
            else if nameSpace == "name-2" { .green }
            else if nameSpace == "name-3" { .purple }
            else { .orange }
            DynamicViewManager.shared(in: testRegionName).present(TestView(count: 0, bgColor: bgColor, flag: nameSpace),
                                                                  name: nameSpace,
                                                                  mode: .stack,
                                                                  configs: [.config(position: stackPosition)])
            
            stackPosition = CGPoint(x: stackPosition.x + 7 > 260 ? 100: stackPosition.x + 7,
                                      y: stackPosition.y + 17 > 317 ? 100: stackPosition.y + 17)
            
            codeStr = "DynamicViewManager.shared(in: testRegionName).present(view, name: viewName, mode: .stack, configs: configs)"
        } else {
            addCustomView()
            codeStr = "DynamicViewManager.shared(in: testRegionName).present(view, name: viewName, mode: .replace, configs: configs)"
        }
    }

    func dimissView() {
        DynamicViewManager.shared(in: testRegionName).dismiss(name: nameSpace)
        codeStr = "DynamicViewManager.shared(in: testRegionName).dismiss(name: \(nameSpace))"
    }
    
    func dismissQueue() {
        stopTimer()
        animation.dismiss(isAll: true)
        animation.dismiss(isAll: true)
        animation.dismiss(isAll: true)
        codeStr = "animation.dismiss(isAll: true)"
    }
    
    
    func startTimer() {
        nameSpace = "Queue私有专属"
        codeStr = "animation.lineOut(TestView(count: count), offset: 260, isReverse: true)"
        linePresentInvoke()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] timer in
            self?.linePresentInvoke()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func showMoreQueues() {
        showMoreQueue = !showMoreQueue
        codeStr = ""
        
        if showMoreQueue && timer == nil {
            startTimer()
        } else if !showMoreQueue {
            stopTimer()
        }
    }
    
    func linePresentInvoke() {
        count = count + 1
        if count % 2 == 0 {
            animation.lineOut(TestView(count: count), offset: 260, isReverse: true)
        }
        
        if showMoreQueue {
            animation1.lineOut(TestView(count: count, bgColor: .purple), offset: 260)
            if count % 8 == 0 {
                animation2.lineOut(TestView(count: count, bgColor: .pink), offset: 260)
            }
        }
    }
    
    private func addCustomView() {
        let top = CGPoint(x: width / 2, y: 100)
        let right = CGPoint(x: width / 2 + 150, y: 250)
        let bottom = CGPoint(x: width / 2, y: 400)
        let left = CGPoint(x: width / 2 - 150, y: 250)
        DynamicViewManager
            .shared(in: testRegionName)
            .present(TestView(count: -1),
                     name: nameSpace,
                     configs: [
                        .config(position: top),
                        .config(position: right,
                                animation: .easeIn(duration: 0.2),
                                opacity: 0.2, scale: 0.8),
                        .config(position: bottom,
                                animation: .easeOut(duration: 0.5),
                                opacity: 1, scale: 1),
                        .config(position: left,
                                animation: .easeOut(duration: 0.5),
                                opacity: 0.2, scale: 0.8),
                        .config(position: top,
                                animation: .easeIn(duration: 0.3),
                                opacity: 1, scale: 1)
                     ])
    }
    
    
}

