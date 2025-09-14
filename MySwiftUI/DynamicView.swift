//
//  File.swift
//  AppUI
//
//  Created by linlixiang on 2025/9/10.
//

import SwiftUI

public struct DyViewAniConfig {
    public private(set) var position: CGPoint?
    public private(set) var opacity: Double = 1
    public private(set) var animation: Animation?
    public private(set) var duration: Double = 0.0
    private init(position: CGPoint? = nil, opacity: Double = 1.0, animation: Animation? = nil, duration: Double = 0) {
        self.position = position
        self.duration = duration
        self.opacity = opacity
        self.animation = animation
    }
    public static func config(position: CGPoint? = nil, animation: Animation? = .easeInOut(duration: 0.3), duration: Double = 0, opacity: Double = 1.0) -> DyViewAniConfig {
        return DyViewAniConfig(position: position, opacity: 1.0, animation: animation, duration: duration)
    }
    
    public static func center(animation: Animation? = .easeInOut(duration: 0.3), duration: Double = 0.3, opacity: Double = 1.0) -> DyViewAniConfig {
        return DyViewAniConfig(opacity: 1.0, animation: animation, duration: duration)
    }
}

struct DynamicViewListItem {
    var id = UUID()
    var name: String = ""
    var view: AnyView
    var aniConfig: DyViewAniConfig?
    init(view: AnyView, name: String = "", aniConfig: DyViewAniConfig? = nil) {
        self.view = view
        self.name = name
        self.aniConfig = aniConfig
    }
}



public class DynamicViewRegionControl: ObservableObject {
    public enum PresentMode {
        case replace  // 覆盖（默认）
        case stack    // 堆叠
    }
    public static let shared = DynamicViewRegionControl()
    @Published var viewStacks = [DynamicViewListItem]()
    
    public func present<Content: View>(_ view: Content,
                                       name: String = "",
                                       mode: PresentMode = .replace,
                                       configs: [DyViewAniConfig] = []) {
        let viewItem = DynamicViewListItem(view: AnyView(view), name: name, aniConfig: configs.first ?? nil)
        viewStacks = (mode == .stack) ? viewStacks + [viewItem] : (viewStacks.filter { item in item.name != name } + [viewItem])
        let aniConfigs = Array(configs.dropFirst())
        guard !aniConfigs.isEmpty else { return }
        Task {
            await runAnimationConfig(name: name, configs: configs)
        }
    }
    
    public func dismiss(name: String = "",
                        isAll: Bool = false,
                        config: DyViewAniConfig? = nil) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (config?.duration ?? 0)) {
            if isAll {
                self.viewStacks.removeAll()
            } else if let index = self.viewStacks.lastIndex(where: { item in item.name == name }) {
                self.viewStacks.remove(at: index)
            }
        }
        guard let config else { return }
        Task { await runAnimationConfig(name: name, configs: [config]) }
        
    }
    
    private func runAnimationConfig(name: String, configs: [DyViewAniConfig] = []) async {
        for config in configs {
            await MainActor.run {
                guard viewStacks.count > 0 else { return }
                guard let index = viewStacks.firstIndex(where: { item in item.name == name }) else { return }
                var newItem = viewStacks[index]
                newItem.aniConfig = config
                withAnimation(config.animation) {
                    viewStacks[index] = newItem
                }
            }
            try? await Task.sleep(for: .seconds(config.duration))
        }
    }
    
    private func debugPrint(_ str: String) {
        print("DynamicViewRegionControl: \(str)")
    }
    
    private func timeDiff() {
        let now = DispatchTime.now().uptimeNanoseconds
        let microseconds = now / 1000000
        print("毫秒时间戳: \(microseconds)")
    }
}

public class DynamicViewManager {
    
    public static let globalRegion = "DynamicViewControlGlobalName"
    
    private(set) var regionControl = [String: DynamicViewRegionControl]()
    
    private static let manager = DynamicViewManager()
    
    private func getControl(region: String) -> DynamicViewRegionControl {
        if let control = regionControl[region] { return control }
        let control = DynamicViewRegionControl()
        regionControl[region] = control
        return control
    }
    
    public static func shared(in region: String = globalRegion) -> DynamicViewRegionControl {
        manager.getControl(region: region)
    }
}

struct DynamicViewInjector: ViewModifier {
    @ObservedObject var control: DynamicViewRegionControl
    
    let region: String
    
    init(region: String) {
        self.region = region
        self.control = DynamicViewManager.shared(in: region)
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                ZStack {
                    let viewList = control.viewStacks
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
    var initConf: DyViewAniConfig
    var enterAni: DyViewAniConfig
    var leaveAni: DyViewAniConfig
    init(view: AnyView? = nil,
         initConf: DyViewAniConfig? = nil,
         enterAni: DyViewAniConfig? = nil,
         leaveAni: DyViewAniConfig? = nil) {
        self.view = view
        self.initConf = initConf ?? .center()
        self.enterAni = enterAni ?? .center()
        self.leaveAni = leaveAni ?? .center()
    }
}

final public class DynamicViewQueue {
    public enum AxisOrth {
        case horizontal(orth: Double)
        case vertical(orth: Double)
    }
    private let name = UUID().uuidString
    private var regionName: String = DynamicViewManager.globalRegion
    
    private var viewList: [DynamicViewQueueItem] = []
    private var viewAxis: AxisOrth = .horizontal(orth: 0)
    private var viewOrth: Double = 0.0
    
    private var duration: Double = 3.0
    private var dismissTimer: Timer?
    
    private var playingItem: DynamicViewQueueItem?
    private var pendingItem = DynamicViewQueueItem()
    
    public init(duration: Double, axis: AxisOrth = .horizontal(orth: 0), inRegion: String = DynamicViewManager.globalRegion) {
        self.duration = duration
        self.viewAxis = axis
        self.regionName = inRegion
    }
    
    public func pushView(_ view: AnyView, initCenter: Double) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: initCenter)
        let config = DyViewAniConfig.config(position: pos)
        pendingItem = DynamicViewQueueItem(view: view, initConf: config, enterAni: nil, leaveAni: nil)
        return self
    }
    
    public func enter(_ paraCenter: Double, axis: AxisOrth? = nil, animation: Animation = .easeInOut(duration: 0.3), duration: Double = 0.3) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        let config = DyViewAniConfig.config(position: pos, animation: animation, duration: duration)
        pendingItem.enterAni = config
        return self
    }
    
    public func leave(_ paraCenter: Double, axis: AxisOrth? = nil, animation: Animation = .easeInOut(duration: 0.3), duration: Double = 0.3) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        let toConfig = DyViewAniConfig.config(position: pos, animation: animation, duration: duration)
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
        DynamicViewManager.shared(in: regionName).present(item.view, name: name, configs: [item.initConf, item.enterAni])
        let fixTime = duration - item.leaveAni.duration
        dismissTimer = Timer.scheduledTimer(withTimeInterval: fixTime > 0 ? fixTime: 0.3, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.dismiss()
        }
    }
    
    public func dismiss(isAll: Bool = false, withAni: Bool = true) {
        debugPrint("dismiss")
        dismissTimer?.invalidate()
        dismissTimer = nil
        isAll ? viewList.removeAll(): ()
        guard let item = playingItem else { return }
        DynamicViewManager.shared(in: regionName).dismiss(name: name, isAll: isAll, config: item.leaveAni)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + item.leaveAni.duration) {
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
