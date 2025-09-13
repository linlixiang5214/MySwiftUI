//
//  ContentView.swift
//  MySwiftUI
//
//  Created by 林立祥 on 2025/7/20.
//

import SwiftUI

public let testRegionName = "mainView"

struct ContentView: View {
    
    private var model = testModel()
    
    @State private var curIndex: Int = 0
    
    var body: some View {
        
        VStack(spacing: 15) {
            
            VStack {
                Spacer()
                Text("这就是一个画布")
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .background(.yellow.opacity(0.2))
            .enableDynamicViewInjection(in: testRegionName)
    
            HStack {
                Spacer()
                Button {
                    addView()
                } label: {
                    Text("添加视图")
                }
                Spacer()
                Button {
                    removeTop()
                } label: {
                    Text("移除顶部视图")
                }
                Spacer()
            }
            
            Spacer().frame(height: 10)
            
            Button {
                startQueue()
            } label: {
                Text("开启定时器队列展示")
            }
            
            Button {
                model.dismiss()
            } label: {
                Text("移除队列顶部")
            }
            
            Button {
                stopTimer()
            } label: {
                Text("移除定时器")
            }
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(.yellow.opacity(0.1))
        
        
    }
    
    func startQueue() {
        model.start()
    }
    
    func removeTop() {
        model.dimissView()
    }
    
    func stopTimer() {
        model.stopTimer()
    }
    
    func addView() {
        model.addView()
    }
    
}

public class testModel {
    
    let animation = DynamicViewQueue(duration: 12, axis: .horizontal, orth: 250, inRegion: testRegionName)
    
    private let width = UIScreen.main.bounds.width
    
    private let height = UIScreen.main.bounds.height
    
    private var timer: Timer?
    
    private var count: Int = 0
    
    func start() {
        self.testFunc()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            self.testFunc()
        }
    }
    
    func testFunc() {
        count = count + 1
//        print("testFunc call: \(count)")
        
//        let view = TestView().position(x: width / 2, y: 400)
        
        animation
            .pushView(AnyView(TestView(count: count)), initCenter: width)
            .enter(width / 2)
            .leave(0, axis: .vertical(width / 2))
            .show()
            
    }
    
    func dismiss() {
        animation.dismiss()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func addView() {
        DynamicViewManager.shared.present(TestView(count: -1), in: testRegionName)
    }
    
    func dimissView() {
        DynamicViewManager.shared.dismiss(in: testRegionName)
    }
}

