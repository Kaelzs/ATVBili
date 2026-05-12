//
//  BLMenuLineCollectionViewCell.swift
//  BilibiliLive
//
//  Created by ManTie on 2024/7/4.
//

import UIKit

class BLMenuLineCollectionViewCell: BLSettingLineCollectionViewCell {
    var iconImageView = UIImageView()
    private let foregroundColor = UIColor.white
    private let selectedForegroundColor = UIColor(white: 0.08, alpha: 0.92)
    private let inactiveSelectedBackgroundColor = UIColor.white.withAlphaComponent(0.22)

    override func addsubViews() {
        contentView.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.clipsToBounds = true
        effectView.effect = nil
        effectView.backgroundColor = UIColor.clear

        selectedWhiteView.backgroundColor = UIColor.white
        selectedWhiteView.isHidden = !isFocused
        effectView.contentView.addSubview(selectedWhiteView)
        selectedWhiteView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(1)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        selectedWhiteView.alpha = 1

        effectView.contentView.addSubview(iconImageView)
        let imageViewHeight = 32.0
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(imageViewHeight)
            make.left.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
        }

        effectView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalTo(iconImageView)
        }
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        updateView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let capsuleRadius = bounds.height / 2
        effectView.layer.cornerRadius = capsuleRadius
        effectView.layer.cornerCurve = .continuous
        selectedWhiteView.layer.cornerRadius = (bounds.height - 2) / 2
        selectedWhiteView.layer.cornerCurve = .continuous
    }

    override func updateView() {
        let isFocusedState = isFocused
        let isSelectedState = isSelected
        selectedWhiteView.isHidden = !(isFocusedState || isSelectedState)
        if isFocusedState {
            selectedWhiteView.backgroundColor = UIColor.white
        } else if isSelectedState {
            selectedWhiteView.backgroundColor = inactiveSelectedBackgroundColor
        }

        let foreground = isFocusedState ? selectedForegroundColor : foregroundColor
        titleLabel.textColor = foreground
        iconImageView.tintColor = foreground
        effectView.alpha = 1
    }
}
