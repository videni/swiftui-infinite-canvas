import SwiftUI
import UIKit

struct InfiniteScrollViewRepresentable<Content: View>: UIViewRepresentable {
    let controller: InfiniteCanvasController
    @ViewBuilder let content: () -> Content
    
    func updateUIView(_ uiView: InfiniteScrollView<Content>, context: Context) {
        uiView.hostingController.rootView = content()
    }
    
    func makeUIView(context: Context) -> InfiniteScrollView<Content> {
        let scrollView = InfiniteScrollView<Content>()
        scrollView.controller = controller
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        scrollView.hostingController = hostingController
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: hostingController.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
        ])
        return scrollView
    }
}

class InfiniteScrollView<Content: View>: UIView {
    var controller: InfiniteCanvasController!
    var hostingController: UIHostingController<Content>!
    
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    
    // 缩放相关属性，类似 UIScrollView
    private var initialScale: CGFloat = 1.0
    private var currentScale: CGFloat = 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        // 平移手势
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
        
        // 缩放手势
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        addGestureRecognizer(pinchGesture)
        
        // 双击缩放手势
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        controller.pan(deltaX: translation.x, deltaY: translation.y)
        gesture.setTranslation(.zero, in: self)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            // 记录开始时的缩放值
            initialScale = controller.scale
            currentScale = initialScale
        case .changed:
            let point = gesture.location(in: self)
            // 计算目标缩放值
            let targetScale = initialScale * gesture.scale
            // 计算缩放增量
            let scaleIncrement = targetScale - currentScale
            // 应用缩放，使用更小的系数来降低灵敏度
            controller.magnify(by: scaleIncrement * 0.7, point: point)
            currentScale = targetScale
        case .ended, .cancelled:
            // 手势结束，重置状态
            initialScale = 1.0
            currentScale = 1.0
        default:
            break
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        controller.magnify(by: 1.0, point: point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        controller.setFrameSize(size: frame.size)
    }
}
