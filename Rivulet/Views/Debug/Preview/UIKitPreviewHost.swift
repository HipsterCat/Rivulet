#if DEBUG
import SwiftUI
import UIKit

/// Pins a UIKit view on a black canvas for Xcode Previews — same geometry as
/// the existing hero/detail preview hosts.
struct UIKitPreviewHost<Content: UIView>: UIViewRepresentable {
    var leading: CGFloat = 80
    var bottom: CGFloat = 48
    var top: CGFloat = 40
    let make: () -> Content

    func makeUIView(context: Context) -> UIView {
        let box = UIView()
        box.backgroundColor = .black
        let view = make()
        view.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: leading),
            view.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -bottom),
            view.topAnchor.constraint(greaterThanOrEqualTo: box.topAnchor, constant: top),
            view.trailingAnchor.constraint(lessThanOrEqualTo: box.trailingAnchor, constant: -leading)
        ])
        return box
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Lays out a fixed-size UIKit view for cell previews.
struct UIKitCellPreviewHost<Cell: UIView>: UIViewRepresentable {
    let width: CGFloat
    let height: CGFloat
    let leading: CGFloat
    let top: CGFloat
    let configure: (Cell) -> Void

    init(
        width: CGFloat,
        height: CGFloat,
        leading: CGFloat = 80,
        top: CGFloat = 48,
        configure: @escaping (Cell) -> Void
    ) {
        self.width = width
        self.height = height
        self.leading = leading
        self.top = top
        self.configure = configure
    }

    func makeUIView(context: Context) -> UIView {
        let box = UIView()
        box.backgroundColor = .black
        let cell = Cell(frame: CGRect(x: 0, y: 0, width: width, height: height))
        configure(cell)
        cell.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(cell)
        NSLayoutConstraint.activate([
            cell.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: leading),
            cell.topAnchor.constraint(equalTo: box.topAnchor, constant: top),
            cell.widthAnchor.constraint(equalToConstant: width),
            cell.heightAnchor.constraint(equalToConstant: height)
        ])
        return box
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
