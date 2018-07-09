import Foundation
import UIKit
import FastModule
import YogaKit
import Aspects

public protocol Layoutable: Module, ExternalType {
    var view: UIView { get }
    
    func listViewSize(container size: CGSize, pattern: String, parameter: [String: Any]?) -> CGSize
    
    func addChildLayoutable(id: String, layoutable: Layoutable)
    
    @discardableResult
    func addChildLayoutable(id: String, request: Request) -> Layoutable
    
    var childLayoutables: [Layoutable]? { get }
    
    func childLayoutable(id: String) -> Layoutable?
    
    func removeLayoutFromParent()
    
    func layout(_ action: @escaping (YGLayout) -> Void)
    
    func layoutContent()
}

extension Layoutable {
    public func addChildLayoutable(id: String, layoutable: Layoutable) {
        addChildModule(id: id, module: layoutable)
    }
    
    @discardableResult
    public func addChildLayoutable(id: String, request: Request) -> Layoutable {
        if let layoutalbe = ModuleContext.request(request) as? Layoutable {
            addChildLayoutable(id: id, layoutable: layoutalbe)
            view.addSubview(layoutalbe.view)
            layoutalbe.view.yoga.isEnabled = true
            return layoutalbe
        } else {
            fatalError("\(request.module) is not layoutable")
        }
    }
    
    public var childLayoutables: [Layoutable]? {
        return childModules?.filter { $0 is Layoutable }.map { $0 as! Layoutable }
    }
    
    public func childLayoutable(id: String) -> Layoutable? {
        return childModule(id: id) as? Layoutable
    }
    
    public func removeLayoutFromParent() {
        (removeFromParent() as? Layoutable)?.view.removeFromSuperview()
    }
    
    public func layout(_ action: @escaping (YGLayout) -> Void) {
        view.configureLayout {
            action($0)
        }
    }
    
    public func listViewSize(container size: CGSize, pattern: String, parameter: [String: Any]?) -> CGSize {
        return CGSize.zero
    }
}

extension NSObject {
    public func useAs<Type>(type: Type.Type, action: (Type?) -> Void) {
        if let t = self as? Type {
            action(t)
        }
    }
}

extension ExternalType where Self: Layoutable {
    
    private func bridgeProperty<Type>(key: String, type: Type.Type, action: ((UIView) -> Void)? = nil) {
        if let action = action {
            action(view)
        } else {
            bindProperty(key: key, type: type) { [weak self] in
                self?.view.setValue($0, forKey: key)
            }
        }
    }
    
    public func initailBindingActions() {
        let wrappedBlock: @convention(block) (AspectInfo)-> Void = { aspectInfo in
            if !self.view.yoga.isEnabled {
                self.view.yoga.isEnabled = true
            }
            
            self.layoutContent()
            
            self.view.yoga.applyLayout(preservingOrigin: true)
        }
        
        _ = try? view.aspect_hook(#selector(UIView.layoutSubviews), with: [], usingBlock: wrappedBlock)
        
        // 所有 UIView 的绑定
        bridgeProperty(key: "hidden", type: Bool.self)
        bridgeProperty(key: "backgroundColor", type: UIColor.self)
        bridgeProperty(key: "enabled", type: Bool.self)
        bridgeProperty(key: "contentMode", type: UIView.ContentMode.self)
        
        bindAction(pattern: "guesture-tap/:enabled") { [weak self] (parameter, responder, request) in
            let enabled = parameter.truthy(":enabled")
            
            // 当 enabled tap 的时候, 确保用户可交互
            if enabled {
                self?.view.isUserInteractionEnabled = enabled
                self?.enableTapGuestureObservation()
            } else {
                self?.disableTapGuestureObservation()
            }
        }
        
        // UIScrollView 的绑定
        if let scrollView = view as? UIScrollView {
            bindProperty(key: "isPagingEnabled", type: Bool.self) {
                scrollView.isPagingEnabled = $0
            }
        }
    }
}


private let keyTapGuestureHandler = "keyTapGuestureHandler"
extension Layoutable {
    internal func enableTapGuestureObservation() {
        let handler = GestureHandler(handler: self)
        setProperty(key: keyTapGuestureHandler, value: handler)
        view.addGestureRecognizer(LayoutalbeTapGesture(target: handler, action: #selector(GestureHandler.handleTapGuesture)))
    }
    
    internal func disableTapGuestureObservation() {
        view.gestureRecognizers?.forEach {
            if $0 is LayoutalbeTapGesture {
                view.removeGestureRecognizer($0)
            }
        }
        
        removeProperty(key: keyTapGuestureHandler)
    }
}

private class LayoutalbeTapGesture: UITapGestureRecognizer {}

private class GestureHandler {
    weak var handler: Module?
    init(handler: Module) {
        self.handler = handler
    }
    
    @objc func handleTapGuesture(guesture: UITapGestureRecognizer) {
        handler?.notify(action: "guesture-tap", value: guesture.view)
    }
}

