//
//  EmptyLayoutableModule.swift
//  FastModuleLayoutable
//
//  Created by ian luo on 26/03/2018.
//  Copyright © 2018 ianluo. All rights reserved.
//

import Foundation
import FastModule
import YogaKit

open class DynamicLayoutableModule: DynamicModule, Layoutable {
    public var view: UIView = UIView()
    
    public func layoutContent() {
        if let selfLayout = layoutComponents.layout {
            layout(selfLayout)
        }
        
        layoutComponents.subLayouts.forEach {
            childLayoutable(id: $0.key)?.layout($0.value)
        }
    }
    
    public func listViewSize(container size: CGSize, pattern: String, parameter: [String : Any]?) -> CGSize {
        return layoutComponents.listViewSizeAction?(size, pattern, parameter) ?? CGSize.zero
    }
    
    open override class var identifier: String {
        return FastModule.dynamicNameLayoutableModule
    }
    
    public required init(request: Request) {
        super.init(request: request)
    }
    
    private let layoutComponents = DynamicLayoutModuleComponentSubLayouts()
    
    open override func binding() {
        bindAction(pattern: "bind-the-injected-bindings") { [weak self] (parameter, responder, request) in
            if let generatorAction = parameter.value("generatorAction", type: ((Layoutable, DynamicLayoutModuleComponentSubLayouts) -> Void).self) {
                guard let strongSelf = self else { return }
                generatorAction(strongSelf, strongSelf.layoutComponents)
                strongSelf.layoutComponents.injectSubLayoutables(layoutable: strongSelf)
            }
        }
    }
}

public class DynamicLayoutModuleComponentSubLayouts {
    public init() {}
    
    public var subLayoutables: [String: Request] = [:]
    
    public var subLayouts: [String: (YGLayout) -> Void] = [:]
    
    public var layout: ((YGLayout) -> Void)?
    
    var listViewSizeAction: ((CGSize, String, [String: Any]?) -> CGSize)?
    
    public func addSubLayoutable(id: String, layout: @escaping (YGLayout) -> Void) {
        subLayouts[id] = layout
    }
    
    public func addLayout(_ layout: @escaping (YGLayout) -> Void) {
        self.layout = layout
    }
    
    internal func injectSubLayoutables(layoutable: Layoutable) {
        subLayoutables.forEach {
            _ = layoutable.addChildLayoutable(id: $0.key, request: $0.value)
        }
    }
    
    public func setListViewSize(_ action: @escaping (CGSize, String, [String: Any]?) -> CGSize) {
        self.listViewSizeAction = action
    }
}

private struct DynamicLayoutableModuleDescriptor: DynamicModuleDescriptorProtocol {
    public typealias ModuleType = Layoutable
    
    private let generatorAction: (Layoutable, DynamicLayoutModuleComponentSubLayouts) -> Void
    public init(_ generatorAction: @escaping (Layoutable, DynamicLayoutModuleComponentSubLayouts) -> Void) {
        self.generatorAction = generatorAction
    }
    
    private let component = DynamicLayoutModuleComponentSubLayouts()
    
    public func instance(request: Request) -> Layoutable {
        return ModuleContext.request(self.request(request: request)) as! Layoutable
    }
    
    public func request(request: Request) -> Request {
        var request = request
        request["generatorAction"] = generatorAction
        return request
    }
}

public protocol DynamicLayoutableTemplate {
    func setupChildModules(layoutable: Layoutable)
    
    func setupBindings(layoutable: Layoutable)
    
    func setupLayouts(layoutable: Layoutable, layoutComponent: DynamicLayoutModuleComponentSubLayouts)
    
    func setupObservations(layoutable: Layoutable)
    
    static func request(name: String, properties: [String: Any]) -> Request
    
    static func instance(name: String, properties: [String: Any]) -> Layoutable
    
    static func request(name: String, pattern: String, arguments: Any...) -> Request
    
    static func instance(name: String, pattern: String, arguments: Any...) -> Layoutable
    
    init()
}

extension DynamicLayoutableTemplate {
    public static func request(name: String, pattern: String, arguments: Any...) -> Request {
        let request = Request(requestPattern: "//" + DynamicLayoutableModule.identifier + "-" + name + "/" + pattern, arguments: arguments)
        return DynamicLayoutableBuilder(template: Self.init()).buildRequest(request: request)
    }
    
    public static func instance(name: String, pattern: String, arguments: Any...) -> Layoutable {
        let request = self.request(name: name, pattern: pattern, arguments: arguments)
        return DynamicLayoutableBuilder(template: Self.init()).buildInstance(request: request)
    }
    
    public static func request(name: String, properties: [String: Any]) -> Request {
        let request = Request(requestPattern: "//" + DynamicLayoutableModule.identifier + "-" + name + "/" + "instatiate-properties/#properties", arguments: properties)
        return DynamicLayoutableBuilder(template: Self.init()).buildRequest(request: request)
    }
    
    public static func instance(name: String, properties: [String: Any]) -> Layoutable {
        let request = Request(requestPattern: "//" + DynamicLayoutableModule.identifier + "-" + name + "/" + "instatiate-properties/#properties", arguments: properties)
        return DynamicLayoutableBuilder(template: Self.init()).buildInstance(request: request)
    }
}

fileprivate struct DynamicLayoutableBuilder {
    private var template: DynamicLayoutableTemplate?
    public init(template: DynamicLayoutableTemplate) {
        self.template = template
    }
    
    fileprivate func buildDescriptor() -> DynamicLayoutableModuleDescriptor {
        return DynamicLayoutableModuleDescriptor { layoutable, layoutComponent in
            self.template?.setupChildModules(layoutable: layoutable)
            self.template?.setupBindings(layoutable: layoutable)
            self.template?.setupLayouts(layoutable: layoutable, layoutComponent: layoutComponent)
            self.template?.setupObservations(layoutable: layoutable)
        }
    }
    
    fileprivate func buildInstance(request: Request) -> Layoutable {
        return buildDescriptor().instance(request: request)
    }
    
    fileprivate func buildRequest(request: Request) -> Request {
        return buildDescriptor().request(request: request)
    }
}
