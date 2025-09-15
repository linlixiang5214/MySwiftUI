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
    public private(set) var scale: Double = 1
    public private(set) var animation: Animation?
    public private(set) var duration: Double = 0.0
    private init(position: CGPoint? = nil, opacity: Double = 1.0, scale: Double = 1.0, animation: Animation? = nil, duration: Double = 0) {
        self.position = position
        self.duration = duration
        self.opacity = opacity
        self.scale = scale
        self.animation = animation
    }
    public static func config(position: CGPoint? = nil, animation: Animation? = .easeInOut(duration: 0.3), duration: Double = 0.3, opacity: Double = 1.0, scale: Double = 1.0) -> DyViewAniConfig {
        return DyViewAniConfig(position: position, opacity: 1.0, scale: scale, animation: animation, duration: duration)
    }
    
    public static func center(animation: Animation? = .easeInOut(duration: 0.3), duration: Double = 0.3, opacity: Double = 1.0, scale: Double = 1.0) -> DyViewAniConfig {
        return DyViewAniConfig(opacity: 1.0, scale: scale, animation: animation, duration: duration)
    }
    public func withPos(_ pos: CGPoint?) -> DyViewAniConfig {
        var config = self
        config.position = pos ?? config.position
        return config
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
    
    @Published var viewStacks = [DynamicViewListItem]()
    /// name：一个region 可能有多个 view，可以用name进行命名
    /// mode：替换 堆叠
    /// config:  动画效果，有动画的话最少要有两个元素（初始config，结束config）
    public func present<Content: View>(_ view: Content,
                                       name: String = "",
                                       mode: PresentMode = .replace,
                                       configs: [DyViewAniConfig] = []) {
        let viewItem = DynamicViewListItem(view: AnyView(view), name: name, aniConfig: configs.first ?? nil)
        viewStacks = (mode == .stack) ? viewStacks + [viewItem] : (viewStacks.filter { item in item.name != name } + [viewItem])
        let aniConfigs = Array(configs.dropFirst())
        guard !aniConfigs.isEmpty else { return }
        Task { await runAnimationConfig(name: name, configs: aniConfigs) }
    }
    /// 移除name下最后一个视图
    public func dismiss(name: String = "", isAll: Bool = false, config: DyViewAniConfig? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (config?.duration ?? 0)) {
            if isAll {
                self.viewStacks.removeAll()
            } else if let index = self.viewStacks.lastIndex(where: { item in item.name == name }) {
                self.viewStacks.remove(at: index)
            }
        }
        guard let config, !isAll else { return }
        Task { await runAnimationConfig(name: name, configs: [config]) }
    }
    /// 遍历执行动画配置
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
            try? await Task.sleep(for: .seconds(1))
        }
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
    
    public static func activeSign(in region: String = globalRegion, _ control: DynamicViewRegionControl?) {
        if manager.regionControl[region] != nil && control != nil { return }
        manager.regionControl[region] = control
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
                GeometryReader { contentProxy in
                    ZStack {
                        let viewList = control.viewStacks
                        ForEach(viewList, id: \.id) { item in
                            item.view
                                .scaleEffect(item.aniConfig?.scale ?? 1)
                                .opacity(item.aniConfig?.opacity ?? 1)
                                .position(item.aniConfig?.position ?? CGPoint(x: contentProxy.size.width / 2, y: contentProxy.size.height / 2))
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    DynamicViewManager.activeSign(in: region, control)
                }
                .onDisappear {
                    DynamicViewManager.activeSign(in: region, nil)
                }
            }
    }
}

public extension View {
    func enableDynamicViewInjection(in region: String = DynamicViewManager.globalRegion) -> some View {
        self.modifier(DynamicViewInjector(region: region))
    }
}

final public class DynamicViewQueue {
    struct DynamicViewQueueItem {
        var view: AnyView?
        var configs: [DyViewAniConfig] = []
        init(view: AnyView? = nil, initConfig: DyViewAniConfig = .center()) {
            self.view = view
            configs.insert(initConfig, at: 0)
        }
    }
    
    public enum AxisOrth {
        case horizontal(orth: Double)
        case vertical(orth: Double)
    }
    
    private let name = UUID().uuidString
    private let regionName: String
    
    private var viewList: [DynamicViewQueueItem] = []
    private var viewAxis: AxisOrth = .horizontal(orth: 0)
    
    private var duration: Double = 3.0
    private var dismissTimer: Timer?
    
    private var playingItem: DynamicViewQueueItem?
    private var pendingItem: DynamicViewQueueItem?
    
    public init(duration: Double, axis: AxisOrth = .horizontal(orth: 0), inRegion: String = DynamicViewManager.globalRegion) {
        self.duration = duration
        self.viewAxis = axis
        self.regionName = inRegion
    }
    /// 开始配置，默认居中，父视图frame固定，不然position会不可控
    public func pushView(_ view: AnyView, _ paraCenter: Double?, axis: AxisOrth? = nil, config: DyViewAniConfig? = nil) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        pendingItem = DynamicViewQueueItem(view: view, initConfig: config?.withPos(pos) ?? .config(position: pos))
        return self
    }
    /// 视图中心点 沿着axis方向的 绝对位置，axis 默认 init 可设置，orth 为正交方向偏移
    public func reach(_ paraCenter: Double?, axis: AxisOrth? = nil, config: DyViewAniConfig? = nil) -> DynamicViewQueue {
        let pos = generatePosition(paraCenter: paraCenter, axis: axis)
        pendingItem?.configs.append(config?.withPos(pos) ?? .config(position: pos))
        return self
    }
    /// 加到队列中，相当于配置完成，参数与enter一样
    public func finish() -> DynamicViewQueue {
        if let pendingItem { viewList.append(pendingItem) }
        pendingItem = nil
        return self
    }
    
    public func show() {
        guard playingItem == nil, viewList.count > 0 else { return }
        playingItem = viewList.removeFirst()
        guard let item = playingItem else { return }
        DynamicViewManager.shared(in: regionName).present(item.view, name: name, configs: Array(item.configs.dropLast()))
        let fixTime = duration - (item.configs.last?.duration ?? 0)
        dismissTimer = Timer.scheduledTimer(withTimeInterval: fixTime > 0 ? fixTime: 0.3, repeats: false) { [weak self] timer in
            timer.invalidate()
            self?.dismiss()
        }
    }
    
    public func dismiss(isAll: Bool = false, withAni: Bool = true) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        isAll ? viewList.removeAll(): ()
        guard let item = playingItem else { return }
        DynamicViewManager.shared(in: regionName).dismiss(name: name, isAll: isAll, config: item.configs.last)
        DispatchQueue.main.asyncAfter(deadline: .now() + (item.configs.last?.duration ?? 0.0)) {
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
}
