import SwiftUI
import UIKit

let visibleRectIntersectionPadding = CGSize(width: 100, height: 100)

public struct CanvasPosition: ViewModifier {
    @State private var canvasPosition: CGPoint = .zero
    @State private var size: CGSize = .zero
    
    let position: CGPoint
    let controller: InfiniteCanvasController
    
    init(position: CGPoint, controller: InfiniteCanvasController) {
        self.position = position
        self.controller = controller
        _canvasPosition = State(initialValue: position - controller.contentOffset)
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isWithinVisibleRect(size: size) {
                content
                    .offset(x: canvasPosition.x, y: canvasPosition.y)
                    .scaleEffect(controller.scale, anchor: .topLeading)
                    .background(
                        GeometryReader { geometryProxy in
                            Color.clear
                                .preference(key: CanvasItemSize.self, value: geometryProxy.size)
                        }
                    )
            } else {
                EmptyView()
            }
        }
        .onPreferenceChange(CanvasItemSize.self) { newSize in
            size = newSize
        }
        .onReceive(controller.$contentOffset) { offset in
            canvasPosition = CGPoint(
                x: position.x - offset.x,
                y: position.y - offset.y
            )
        }
    }
    
    private func isWithinVisibleRect(size: CGSize) -> Bool {
        let viewBounds = CGRect(
            x: position.x,
            y: position.y,
            width: size.width ,
            height: size.height
        )
        return controller.visibleRect.intersects(viewBounds)
    }
}

public extension View {
    func canvasPosition(position: CGPoint, controller: InfiniteCanvasController) -> some View {
        modifier(CanvasPosition(position: position, controller: controller))
    }
}


fileprivate struct CanvasItemSize: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}


func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
