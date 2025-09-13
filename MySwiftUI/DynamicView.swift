//
//  File.swift
//  AppUI
//
//  Created by linlixiang on 2025/9/10.
//

import SwiftUI



public struct DyViewAniConfig {
    public var position: CGPoint?
    public var opacity: Double = 1
    public var animation: Animation?
    public var duration: Double = 0.0
    public init(position: CGPoint? = nil, opacity: Double = 1.0, animation: Animation? = nil, duration: Double = 0) {
        self.position = position
        self.duration = duration
        self.opacity = opacity
        self.animation = animation
    }
}

public struct DynamicViewListItem {
    public var id = UUID()
    public var view: AnyView
    public var aniConfig: DyViewAniConfig?
    init(view: AnyView, aniConfig: DyViewAniConfig? = nil) {
        self.view = view
        self.aniConfig = aniConfig
    }
}

public class DynamicViewManager: ObservableObject {
    public enum PresentMode {
        case replace  // 覆盖（默认）
        case stack    // 堆叠
    }
    
    public static let globalRegion = "DynamicViewGlobalName"
    public static let shared = DynamicViewManager()
    @Published var viewStacks: [String: [DynamicViewListItem]] = [:]
    
    
    public func present<Content: View>(_ view: Content, in region: String = globalRegion,
                                       mode: PresentMode = .replace,
                                       aniConfig: DyViewAniConfig? = nil,
                                       initConfig: DyViewAniConfig? = nil) {
        debugPrint("present")
        let viewItem = DynamicViewListItem(view: AnyView(view), aniConfig: DyViewAniConfig(position: initConfig?.position))
        self.viewStacks[region] = if mode == .stack {
            self.viewStacks[region] ?? [] + [viewItem]
        } else {
            [viewItem]
        }
        
        self.activeViewUseAni(in: region, config: aniConfig)
    }
    
    public func dismiss(in region: String = globalRegion,
                        isAll: Bool = false,
                        aniConfig: DyViewAniConfig? = nil) {
        
        activeViewUseAni(in: region, config: aniConfig)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (aniConfig?.duration ?? 0)) {
            self.debugPrint("dismiss")
            if var stack = self.viewStacks[region], !stack.isEmpty, !isAll {
                stack.removeLast()
                self.viewStacks[region] = stack.isEmpty ? nil : stack
            } else {
                self.viewStacks.removeValue(forKey: region)
            }
        }
    }
    
    public func activeViewUseAni(in region: String, config: DyViewAniConfig? = nil) {
        debugPrint("activeViewUseAni: count: \(viewStacks[region]?.count ?? 0), in: \(region), duration: \(config?.duration ?? -1)")
        guard let config else { return }
        let presentCount = viewStacks[region]?.count ?? 0
        guard var regionStack = viewStacks[region] else { return }
        regionStack[presentCount - 1].aniConfig = config
        withAnimation(config.animation) {
            viewStacks[region] = regionStack
        }
    }
    
    private func debugPrint(_ str: String) {
        print("DynamicViewManager: \(str)")
    }
}

struct DynamicViewInjector: ViewModifier {
    @ObservedObject private var injector = DynamicViewManager.shared
    
    let region: String
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                ZStack {
                    let viewList = injector.viewStacks[region] ?? []
                    ForEach(viewList, id: \.id) { item in
                        if let position = item.aniConfig?.position {
                            item.view
                                .opacity(item.aniConfig?.opacity ?? 1)
                                .position(position)
                        } else {
                            item.view
                                .opacity(item.aniConfig?.opacity ?? 1)
                        }
                    }
                }
            }
    }
}

public extension View {
    func enableDynamicViewInjection(in region: String = DynamicViewManager.globalRegion) -> some View {
        self.modifier(DynamicViewInjector(region: region))
    }
}

public enum DynamicViewQueueAxis {
    case horizontal(orth: Double)
    case vertical(orth: Double)
    func getOrthValue() -> Double{
        switch self {
        case .horizontal(let orth):
            return orth
        case .vertical(let orth):
            return orth
        }
    }
}

struct DynamicViewQueueItem {
    var view: AnyView?
    var initConf: DyViewAniConfig?
    var enterAni: DyViewAniConfig?
    var leaveAni: DyViewAniConfig?
    init(view: AnyView? = nil, position: CGPoint? = nil, initConf: DyViewAniConfig? = nil, enterAni: DyViewAniConfig? = nil, leaveAni: DyViewAniConfig? = nil) {
        self.view = view
        self.initConf = initConf
        self.enterAni = enterAni
        self.leaveAni = leaveAni
    }
}

final public class DynamicViewQueue {
    public enum AxisOrth {
        case horizontal(Double)
        case vertical(Double)
    }
    
    private var regionName: String = DynamicViewManager.globalRegion
    
    private var viewList: [DynamicViewQueueItem] = []
    private var viewAxis: AxisOrth = .horizontal(0)
    private var viewOrth: Double = 0.0
    
    private var duration: Double = 3.0
    private var dismissTimer: Timer?
    
    private var playingItem: DynamicViewQueueItem?
    private var pendingItem = DynamicViewQueueItem()
    
    public init(duration: Double, axis: AxisOrth = .horizontal(0), inRegion: String = DynamicViewManager.globalRegion) {
        self.duration = duration
        self.viewAxis = axis
        self.regionName = inRegion
    }
    
    public func pushView(_ view: AnyView, initCenter: Double) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: initCenter)
        let config = DyViewAniConfig(position: pos)
        pendingItem = DynamicViewQueueItem(view: view, initConf: config, enterAni: nil, leaveAni: nil)
        return self
    }
    
    public func enter(_ paraCenter: Double, axis: AxisOrth? = nil, animation: Animation = .easeInOut(duration: 0.3), duration: Double = 0.3) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        let config = DyViewAniConfig(position: pos, animation: animation, duration: duration)
        pendingItem.enterAni = config
        return self
    }
    
    public func leave(_ paraCenter: Double, axis: AxisOrth? = nil, animation: Animation = .easeInOut(duration: 0.3), duration: Double = 0.3) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        let toConfig = DyViewAniConfig(position: pos, animation: animation, duration: duration)
        pendingItem.leaveAni = toConfig
        viewList.append(pendingItem)
        pendingItem = DynamicViewQueueItem()
        return self
    }
    
    public func show() {
        debugPrint("show")
        guard playingItem == nil, viewList.count > 0 else { return }
        playingItem = viewList.removeFirst()
        realShow()
    }
    
    private func realShow() {
        debugPrint("realShow")
        guard let item = playingItem else { return }
        DynamicViewManager.shared.present(item.view, in: regionName, aniConfig: item.enterAni, initConfig: item.initConf)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.dismiss()
        }
    }
    
    public func dismiss(isAll: Bool = false, withAni: Bool = true) {
        debugPrint("dismiss")
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        guard let item = playingItem else { return }
        DynamicViewManager.shared.dismiss(in: self.regionName, isAll: isAll, aniConfig: item.leaveAni)
        DispatchQueue.main.asyncAfter(deadline: .now() + (item.leaveAni?.duration ?? 0) + 0.05) {
            self.playingItem = nil
            self.show()
        }
    }
    
    private func generatePosition(paraCenter: Double?, axis: DynamicViewQueue.AxisOrth? = nil) -> CGPoint? {
        guard let paraCenter else { return nil }
        let realAxis: DynamicViewQueue.AxisOrth = axis ?? viewAxis
        switch realAxis {
        case .horizontal(let orth):
            return CGPoint(x: paraCenter, y: orth)
        case .vertical(let orth):
            return CGPoint(x: orth, y: paraCenter)
        }
    }
    
    private func debugPrint(_ str: String) {
        print("DynamicViewQueue: \(str)")
        
    }
}
