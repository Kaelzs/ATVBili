//
//  HistoryViewController.swift
//  BilibiliLive
//
//  Created by whw on 2021/4/15.
//

import Alamofire
import SwiftyJSON
import UIKit

class HistoryViewController: UIViewController, SidebarMenuPresentable {
    let collectionVC = FeedCollectionViewController()
    var backMenuAction: (() -> Void)? {
        didSet {
            collectionVC.backMenuAction = backMenuAction
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionVC.styleOverride = .sideBar
        collectionVC.backMenuAction = backMenuAction
        collectionVC.show(in: self)
        collectionVC.didSelect = {
            [weak self] in
            self?.goDetail(with: $0 as! HistoryData)
        }
    }

    func goDetail(with history: HistoryData) {
        let detailVC = VideoDetailViewController.create(aid: history.aid, cid: history.cid ?? 0)
        detailVC.present(from: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension HistoryViewController: RefreshableTab {
    func reloadData() {
        WebRequest.requestHistory { [weak self] datas in
            self?.collectionVC.displayDatas = datas
        }
    }
}
