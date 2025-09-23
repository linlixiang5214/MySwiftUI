//
//  DynamicViewQueue.swift
//  MySwiftUI
//
//  Created by linlixiang on 2025/9/18.
//

import SwiftUI

final public class DynamicViewQueue {
    struct DynamicViewQueueItem {
        var view: AnyView?
        var priority: Int = 1
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
    
    private var duration: Double = 0
    private var dismissTimer: Timer?
    
    private var playingItem: DynamicViewQueueItem?
    private var pendingItem: DynamicViewQueueItem?
    
    public init(duration: Double = 0, axis: AxisOrth = .horizontal(orth: 0), inRegion: String = DynamicViewManager.globalRegion) {
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
        viewList.sort { $0.priority > $1.priority }
        pendingItem = nil
        
        return self
    }
    
    public func show() {
        guard playingItem == nil, viewList.count > 0 else { return }
        playingItem = viewList.removeFirst()
        guard let item = playingItem else { return }
        
        DynamicViewManager.shared(in: regionName).present(item.view, name: name, configs: Array(item.configs.dropLast()))
        if duration >= 0 {
            var fixTime = duration - (item.configs.last?.duration ?? 0)
            fixTime = fixTime > 0 ? fixTime: 0.05
            dismissTimer = Timer.scheduledTimer(withTimeInterval: fixTime, repeats: false) { [weak self] timer in
                timer.invalidate()
                self?.dismiss()
            }
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

public enum DynamicViewQueuePriority: Int {
    case lowest     = 0
    case low        = 1
    case middle     = 2
    case high       = 3
    case highest    = 4
}

//MARK: Eazy Using
public extension DynamicViewQueue {
    func lineOut(_ theView: some View, offset: CGFloat? = nil, isReverse: Bool = false) {
        let axisLen: CGFloat = {
            switch viewAxis {
            case .horizontal: return UIScreen.main.bounds.width
            case .vertical: return UIScreen.main.bounds.height
            }
        }()
        
        let axisOffset = offset ?? (axisLen / 2)
        let (startPos, endPos) = isReverse ? (axisLen + axisOffset, -axisOffset): (-axisOffset, axisLen + axisOffset)
        pushView(AnyView(theView), startPos)
            .reach(axisLen / 2)
            .reach(endPos)
            .finish()
            .show()
    }
    
    func priority(_ priority: DynamicViewQueuePriority) {
        pendingItem?.priority = priority.rawValue
    }
}
