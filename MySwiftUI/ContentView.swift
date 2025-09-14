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
        
        VStack(spacing: 20) {
            
            VStack {
                Spacer()
                Text("这就是一个画布")
                    .foregroundStyle(.black)
                Spacer().frame(height: 10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .background(.yellow.opacity(0.2))
            .enableDynamicViewInjection(in: testRegionName)
            .clipped()
    
            HStack {
                Spacer()
                Button {
                    addView()
                } label: {
                    Text("添加普通视图")
                }
                Spacer()
                Button {
                    removeTop()
                } label: {
                    Text("移除普通视图")
                }
                Spacer()
            }
            
            Spacer().frame(height: 30)
            
            HStack {
                Button {
                    startQueue()
                } label: {
                    Text("开启队列定时器")
                }
                
                Button {
                    stopTimer()
                } label: {
                    Text("移除队列定时器")
                }
                
            }
            Button {
                model.dismiss()
            } label: {
                Text("清空队列")
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
    
    let animation = DynamicViewQueue(duration: 0.6, axis: .horizontal(orth: 300), inRegion: testRegionName)
    
    private let width = UIScreen.main.bounds.width
    
    private let height = UIScreen.main.bounds.height
    
    private var timer: Timer?
    
    private var count: Int = 0
    
    func start() {
        self.testFunc()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            self.testFunc()
        }
    }
    
    func testFunc() {
        count = count + 1
//        print("testFunc call: \(count)")
        
//        let view = TestView().position(x: width / 2, y: 400)
        let contentHeight = 500.0
        let testHeight = 30.0
        
        animation
            .pushView(AnyView(TestView(count: count)), initCenter: width)
            .enter(width / 2)
            .leave(-testHeight, axis: .vertical(orth: width / 2))
            .show()
        
        animation
            .pushView(AnyView(TestView(count: count)), initCenter: width)
            .enter(width / 2)
            .leave(-width / 2)
            .show()
        
        animation
            .pushView(AnyView(TestView(count: count)), initCenter: width)
            .enter(width / 2)
            .leave(contentHeight + testHeight, axis: .vertical(orth: width / 2))
            .show()
        
            
    }
    
    func dismiss() {
        animation.dismiss(isAll: true)
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func addView() {
//        DynamicViewManager.shared(in: testRegionName).present(TestView(count: -1))
        
        DynamicViewManager.shared(in: testRegionName).present(TestView(count: -1), configs: [.config(position: CGPoint(x: 200, y: 200)),
                                                                                             .config(position: CGPoint(x: 100, y: 100))])
    }
    
    func dimissView() {
        DynamicViewManager.shared(in: testRegionName).dismiss()
    }
}

