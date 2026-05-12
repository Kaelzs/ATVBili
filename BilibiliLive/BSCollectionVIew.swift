//
//  BSCollectionVIew.swift
//  BilibiliLive
//
//  Created by ManTie on 2024/7/4.
//

import UIKit

class BSCollectionView: UICollectionView {
    override var canBecomeFocused: Bool {
        return false
    }

    override var preferredFocusedView: UIView? {
        if let selectedIndexPath = indexPathsForSelectedItems?.first,
           let cell = cellForItem(at: selectedIndexPath)
        {
            return cell
        }
        return visibleCells.last
    }
}
