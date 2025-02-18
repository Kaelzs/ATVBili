//
//  BLBackgroundView.swift
//  BilibiliLive
//
//  Created by Kael on 2/18/25.
//

import Kingfisher
import UIKit

class BLBackgroundView: UIView {
    private let imageView0 = UIImageView()
    private let imageView1 = UIImageView()

    private var isDisplayingImage0 = true

    var currentImageView: UIImageView {
        isDisplayingImage0 ? imageView0 : imageView1
    }

    var alternateImageView: UIImageView {
        isDisplayingImage0 ? imageView1 : imageView0
    }

    init() {
        super.init(frame: .zero)

        addSubview(alternateImageView)
        addSubview(currentImageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ source: Kingfisher.Resource?) {
        alternateImageView.kf.setImage(with: source) { [weak self] result in
            guard case .success = result else {
                return
            }

            self?.animateImageTransition()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        currentImageView.frame = bounds
        alternateImageView.frame = bounds
    }

    func animateImageTransition() {
        let imageView = alternateImageView
        imageView.alpha = 0
        insertSubview(imageView, aboveSubview: currentImageView)
        isDisplayingImage0.toggle()

        UIView.animate(withDuration: 0.3) {
            imageView.alpha = 1
        }
    }

    func addBlur() {
        setBlurEffectView(style: .extraDark)
        subviews.filter { $0 is UIVisualEffectView }.forEach { bringSubviewToFront($0) }
    }
}
