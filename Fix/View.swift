//
//  View.swift
//  Fix
//
//  Created by 王渊鸥 on 2019/1/28.
//  Copyright © 2019 王渊鸥. All rights reserved.
//

import UIKit

public enum FixError : Error {
    case notFitGaps
    case tooMoreGaps
}

public protocol FixValue {
    var value:CGFloat { get }
}

extension Int : FixValue {
    public var value:CGFloat { return CGFloat(self) }
}

extension Double : FixValue {
    public var value:CGFloat { return CGFloat(self) }
}

extension CGFloat : FixValue {
    public var value:CGFloat { return CGFloat(self) }
}

public class Fix {
    var c:CGFloat
    var r:CGFloat
    var view:UIView?
    var attitude:NSLayoutConstraint.Attribute
    
    public init(constaint:CGFloat) {
        self.view = nil
        self.c = constaint
        self.r = 1
        self.attitude = .notAnAttribute
    }
    
    public init(_ view:UIView?, attitude:NSLayoutConstraint.Attribute, c:CGFloat = 0, r:CGFloat = 1) {
        self.view = view
        self.c = c
        self.r = r
        self.attitude = attitude
    }
    
    public static func * (_ lhs:Fix, _ rhs:CGFloat) -> Fix {
        return Fix(lhs.view, attitude:lhs.attitude, c: lhs.c, r: rhs)
    }
    
    public static func * (_ lhs:CGFloat, _ rhs:Fix) -> Fix {
        return Fix(rhs.view, attitude:rhs.attitude, c: rhs.c, r: lhs)
    }
    
    public static func + (_ lhs:Fix, _ rhs:CGFloat) -> Fix {
        return Fix(lhs.view, attitude:lhs.attitude, c:rhs, r:lhs.r)
    }
    
    public static func + (_ lhs:CGFloat, _ rhs:Fix) -> Fix {
        return Fix(rhs.view, attitude:rhs.attitude, c: lhs, r: rhs.r)
    }
    
    @discardableResult
    static public func == (_ lhs:Fix, _ rhs:Fix) -> Fix {
        guard let lview = lhs.view else { return lhs }
        
        lview.translatesAutoresizingMaskIntoConstraints = false
        if let rview = rhs.view {
            let con = NSLayoutConstraint(item: lview,
                                         attribute: lhs.attitude,
                                         relatedBy: .equal,
                                         toItem: rview,
                                         attribute: rhs.attitude,
                                         multiplier: rhs.r,
                                         constant: rhs.c)
            if rview.isAncient(of: lview) {
                rview.addConstraint(con)
            } else if lview.isAncient(of: rview) {
                lview.addConstraint(con)
            } else if rhs.attitude == .notAnAttribute {
                lview.addConstraint(con)
            } else {
                lview.superview?.addConstraint(con)
            }
        } else {
            let con = NSLayoutConstraint(item: lview,
                                         attribute: lhs.attitude,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .notAnAttribute,
                                         multiplier: rhs.r,
                                         constant: rhs.c)
            if lhs.attitude == .notAnAttribute {
                lview.addConstraint(con)
            } else {
                lview.superview?.addConstraint(con)
            }
        }
        
        return lhs
    }
    
    @discardableResult
    static public func == <T:FixValue>(_ lhs:Fix, _ rhs:T) -> Fix {
        if let view = lhs.view, let sview = view.superview {
            switch lhs.attitude {
            case .left, .leading, .leftMargin, .leadingMargin, .centerX, .centerXWithinMargins:
                lhs == Fix(sview, attitude: .left, c: rhs.value, r: 1)
            case .right, .rightMargin, .trailing, .trailingMargin:
                lhs == Fix(sview, attitude: .right, c: rhs.value, r: 1)
            case .top, .centerY, .firstBaseline, .topMargin, .centerYWithinMargins:
                lhs == Fix(sview, attitude: .top, c: rhs.value, r: 1)
            case .bottom, .lastBaseline, .bottomMargin:
                lhs == Fix(sview, attitude: .bottom, c: rhs.value, r: 1)
            default:
                lhs == Fix(constaint: rhs.value)
            }
        }
        
        return lhs
    }
}

public enum FixItem {
    case view(fix:UIView)
    case constaint(value:CGFloat)

    init(_ view:UIView) {
        self = .view(fix: view)
    }

    init(_ value:CGFloat) {
        self = .constaint(value: value)
    }
    
    var view:UIView? {
        switch self {
        case .view(let fix):
            return fix
        default:
            return nil
        }
    }
    
    var value:CGFloat? {
        switch self {
        case .constaint(let value):
            return value
        default:
            return nil
        }
    }
}

public protocol FixItemProtocol {
    var item: FixItem { get }
    var isView: Bool { get }
    var isValue: Bool { get }
}

extension CGFloat : FixItemProtocol {
    public var item: FixItem {
        return FixItem(self)
    }
    
    public var isView: Bool { return false }
    public var isValue: Bool { return true }
}

extension Double : FixItemProtocol {
    public var item: FixItem {
        return FixItem(CGFloat(self))
    }
    
    public var isView: Bool { return false }
    public var isValue: Bool { return true }
}

extension Int : FixItemProtocol {
    public var item: FixItem {
        return FixItem(CGFloat(self))
    }
    
    public var isView: Bool { return false }
    public var isValue: Bool { return true }
}


extension UIView : FixItemProtocol {
    public var item: FixItem {
        return FixItem(self)
    }
    
    public var isView: Bool { return true }
    public var isValue: Bool { return false }
}

public extension UIView {
    public var fixLeft:Fix { return Fix(self, attitude: .left) }
    public var fixRight:Fix { return Fix(self, attitude: .right) }
    public var fixTop:Fix { return Fix(self, attitude: .top) }
    public var fixBottom:Fix { return Fix(self, attitude: .bottom) }
    public var fixWidth:Fix { return Fix(self, attitude: .width) }
    public var fixHeight:Fix { return Fix(self, attitude: .height) }
    
    public func isBrother(of view:UIView) -> Bool {
        return self.superview == view.superview && self.superview != nil
    }
    
    public func isAncient(of view:UIView) -> Bool {
        var ancient = view.superview
        while ancient != nil {
            if self == ancient { return true }
            ancient = ancient?.superview
        }
        return false
    }
    
    private func fixListH(views:[UIView], gaps:[CGFloat]) throws {
        if gaps.count != views.count + 1 {
            throw FixError.notFitGaps
        }
        
        var lastView:UIView? = nil
        for n in views.indices {
            let gap = gaps[n]
            let view = views[n]
            
            if let last = lastView {
                view.fixLeft == last.fixRight + gap
            } else {
                view.fixLeft == self.fixLeft + gap
            }
            
            lastView = view
        }
        
        self.fixRight == lastView!.fixRight + gaps.last!
    }
    
    private func fixListV(views:[UIView], gaps:[CGFloat]) throws {
        if gaps.count != views.count + 1 {
            throw FixError.notFitGaps
        }
        
        var lastView:UIView? = nil
        for n in views.indices {
            let gap = gaps[n]
            let view = views[n]
            
            if let last = lastView {
                view.fixTop == last.fixBottom + gap
            } else {
                view.fixTop == self.fixTop + gap
            }
            
            lastView = view
        }
        
        self.fixBottom == lastView!.fixBottom + gaps.last!
    }
    
    private func fillValues<T:FixItemProtocol>(views: inout [UIView], gaps: inout [CGFloat], item:T) throws {
        if item.isValue {
            if gaps.count > views.count + 1 {
                throw FixError.tooMoreGaps
            }
            
            gaps.append(item.item.value!)
        } else {
            if gaps.count == views.count {
                gaps.append(0)
            }
            
            views.append(item.item.view!)
        }
    }
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol>(_ s1:A, _ s2:B) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol, I:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H, _ s9:I) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        try fillValues(views: &views, gaps: &gaps, item: s9)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    
    public func fixH<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol, I:FixItemProtocol, J:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H, _ s9:I, _ s10:J) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        try fillValues(views: &views, gaps: &gaps, item: s9)
        try fillValues(views: &views, gaps: &gaps, item: s10)
        
        try fixListH(views: views, gaps: gaps)
    }
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol>(_ s1:A, _ s2:B) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol, I:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H, _ s9:I) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        try fillValues(views: &views, gaps: &gaps, item: s9)
        
        try fixListV(views: views, gaps: gaps)
    }
    
    
    public func fixV<A:FixItemProtocol, B:FixItemProtocol, C:FixItemProtocol, D:FixItemProtocol, E:FixItemProtocol, F:FixItemProtocol, G:FixItemProtocol, H:FixItemProtocol, I:FixItemProtocol, J:FixItemProtocol>(_ s1:A, _ s2:B, _ s3:C, _ s4:D, _ s5:E, _ s6:F, _ s7:G, _ s8:H, _ s9:I, _ s10:J) throws {
        var views:[UIView] = []
        var gaps:[CGFloat] = []
        
        try fillValues(views: &views, gaps: &gaps, item: s1)
        try fillValues(views: &views, gaps: &gaps, item: s2)
        try fillValues(views: &views, gaps: &gaps, item: s3)
        try fillValues(views: &views, gaps: &gaps, item: s4)
        try fillValues(views: &views, gaps: &gaps, item: s5)
        try fillValues(views: &views, gaps: &gaps, item: s6)
        try fillValues(views: &views, gaps: &gaps, item: s7)
        try fillValues(views: &views, gaps: &gaps, item: s8)
        try fillValues(views: &views, gaps: &gaps, item: s9)
        try fillValues(views: &views, gaps: &gaps, item: s10)
        
        try fixListV(views: views, gaps: gaps)
    }
}

private func fixEqual(_ fix:[Fix]) {
    for n in fix[1...] {
        fix[0] == n
    }
}

private func fixEqual<T:FixValue>(_ value:T, _ fix:[Fix]) {
    for n in fix {
        n == value.value
    }
}

public class FixEqual {
    public static func top(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixTop }))
    }
    
    public static func bottom(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixBottom }))
    }
    
    public static func left(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixLeft }))
    }
    
    public static func right(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixRight }))
    }
    
    public static func width(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixWidth }))
    }
    
    public static func height(_ fix:UIView ...) {
        fixEqual(fix.map({ $0.fixHeight }))
    }
    
    public static func top<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixTop }))
    }
    
    public static func bottom<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixBottom }))
    }
    
    public static func left<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixLeft }))
    }
    
    public static func right<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixRight }))
    }
    
    public static func width<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixWidth }))
    }
    
    public static func height<T:FixValue>(_ value:T, _ fix:UIView ...) {
        fixEqual(value, fix.map({ $0.fixHeight }))
    }
}
