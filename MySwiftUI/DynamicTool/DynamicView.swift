//
//  File.swift
//  AppUI
//
//  Created by linlixiang on 2025/9/10.
//

import SwiftUI

/* using in model: manager and control are class type
params: 目标视图，命名空间(可不填)，同一命名空间覆盖或是堆叠(默认replace)，出场动画(可不填，Queue动画基于该能力实现)
DynamicViewManager.shared(in: regionName).present(activeView, name: nameSpace, mode: .stack,
 configs: [.config(animation: .easeIn(duration: 0.2), opacity: 0.2, scale: 0.8)])
DynamicViewManager.shared(in: regionName).dismiss(name: nameSpace)

 simple eg:
 let control = DynamicViewManager.shared(in: regionName)
 control.present(activeView)
 control.dismiss(activeView)
*/

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
        return DyViewAniConfig(position: position, opacity: opacity, scale: scale, animation: animation, duration: duration)
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
    
    @Published private(set) var viewStacks = [DynamicViewListItem]()
    /// manager.shared可以直接使用，自行创建不归入 manager 管理（可手动activeSign加入管理)
    public init() { }
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
    /// 移除name下最后一个视图，可附加一个动画
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
            try? await Task.sleep(nanoseconds: UInt64(config.duration * 1_000_000_000))
        }
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
