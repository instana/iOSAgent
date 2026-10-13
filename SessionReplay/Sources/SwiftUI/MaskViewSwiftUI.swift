//
//  Copyright © 2026 IBM Corp. All rights reserved.
//
import SwiftUI
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
public struct ShieldedUIViewRepresentable: UIViewRepresentable {
    public var onCreate: ((ShieldedUIView) -> Void)?

    public func makeUIView(context: Context) -> ShieldedUIView {
        let wrapper = ShieldedUIView()
        onCreate?(wrapper)
        return wrapper
    }

    public func updateUIView(_ uiView: ShieldedUIView, context: Context) { }
}

@available(iOS 13.0, *)
public struct ShieldedViewModifier: ViewModifier {
    @State private var shieldedUIView: ShieldedUIView?

    public func body(content: Content) -> some View {
        content
//            .background(ShieldedUIViewRepresentable(shieldedUIView: $shieldedUIView))
            .background(ShieldedUIViewRepresentable())
    }
}

@available(iOS 13.0, *)
public extension View {
    func sensitive() -> some View {
        self.modifier(ShieldedViewModifier())
    }

    func sensitiveView() -> some View {
        self.modifier(ShieldedViewModifier())
    }
}

@available(iOS 13.0, *)
public class ShieldedUIView: UIView {
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview != nil {
            InstanaSessionReplay.maskView(self)
            Instana.log("Session replay: ShieldedUIView class didMoveToSuperview() to mask view")
        } else {
            InstanaSessionReplay.unmaskView(self)
            Instana.log("Session replay: ShieldedUIView class didMoveToSuperview() to unmask view")
        }
    }
}

