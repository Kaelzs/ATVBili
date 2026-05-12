//
//  MenusViewController.swift
//  BilibiliLive
//
//  Created by ManTie on 2024/7/4.
//

import Alamofire
import Combine
import Kingfisher
import SwiftyJSON
import UIKit

class MenusViewController: UIViewController, RefreshableTab {
    static func create() -> MenusViewController {
        return UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: String(describing: self)) as! MenusViewController
    }

    @IBOutlet var contentView: UIView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var leftCollectionView: BSCollectionView!
    weak var currentViewController: UIViewController?
    private var menuIsShowing = false

    @IBOutlet var menusView: UIView! {
        didSet {
            if #available(tvOS 26.0, *) {
                menusView.setGlassEffectView(cornerRadius: lessBigSornerRadius, tintColor: UIColor.white.withAlphaComponent(0.06), alpha: 0.96)
                menusView.setBlurEffectView(style: .prominent, cornerRadius: lessBigSornerRadius, alpha: 0.82)
            } else {
                menusView.setBlurEffectView(style: .prominent, cornerRadius: lessBigSornerRadius, alpha: 0.94)
            }
            menusView.setCornerRadius(cornerRadius: lessBigSornerRadius)
        }
    }

    @IBOutlet var homeIcon: UIImageView! {
        didSet {
            homeIcon.setImageColor(color: UIColor(named: "upTitleColor"))
        }
    }

    @IBOutlet var menusLeft: NSLayoutConstraint!
    @IBOutlet var menusViewHeight: NSLayoutConstraint!

    @IBOutlet var vcLeft: NSLayoutConstraint!
    @IBOutlet var collectionTop: NSLayoutConstraint!
    @IBOutlet var headViewLeading: NSLayoutConstraint!
    @IBOutlet var headingViewTop: NSLayoutConstraint!

    @IBOutlet var menuViewWidth: NSLayoutConstraint!

    var menuRecognizer: UITapGestureRecognizer?
    var focusableView = true

    var userName = ""

    var cellModels = [CellModel]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        leftCollectionView.reloadData()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
        leftCollectionView.register(BLMenuLineCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        leftCollectionView.remembersLastFocusedIndexPath = true
        let initialIndexPath = IndexPath(item: 1, section: 0)
        leftCollectionView.selectItem(at: initialIndexPath, animated: false, scrollPosition: .top)
        collectionView(leftCollectionView, didSelectItemAt: initialIndexPath)
        WebRequest.requestLoginInfo { [weak self] response in
            switch response {
            case let .success(json):
                self?.avatarImageView.kf.setImage(with: URL(string: json["face"].stringValue))
                self?.userName = json["uname"].stringValue
            case .failure:
                break
            }
        }
        menusLeft.constant = 40

        menuRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMenuPress))
        menuRecognizer?.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(menuRecognizer!)
        view.backgroundColor = UIColor(named: "mainBgColor")

        if Settings.enableRemotePlayCommand {
            startRequestPlayCommand()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc func handleMenuPress() {
        showMensu()
    }

    @objc func handleRightPress() {
        hiddenMensu()
    }

    func showMensu() {
        NotificationCenter.default.post(name: EVENT_COLLECTION_TO_TOP, object: nil)
        if menuRecognizer != nil {
            view.removeGestureRecognizer(menuRecognizer!)
        }
        // Request a focus update
        view.setNeedsFocusUpdate()

        BLAnimate(withDuration: 0.3) {
            self.leftCollectionView.alpha = 1
            self.homeIcon.alpha = 0
            self.collectionTop.constant = 40
            self.menusViewHeight.constant = 1020
//            self.vcLeft.constant = 340
            self.headViewLeading.constant = 20
            self.headingViewTop.constant = 20
            self.menusView.setCornerRadius(cornerRadius: bigSornerRadius)
            self.usernameLabel.text = self.userName
            self.menuViewWidth.constant = 320
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.menuIsShowing = true
            self.leftCollectionView.setNeedsLayout()
            self.leftCollectionView.layoutIfNeeded()
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }

    func hiddenMensu() {
        BLAnimate(withDuration: 0.3) {
            self.leftCollectionView.alpha = 0
            self.homeIcon.alpha = 1
            self.collectionTop.constant = 0
            self.menusViewHeight.constant = 60
//            self.vcLeft.constant = 0
            self.headViewLeading.constant = 7
            self.headingViewTop.constant = 0
            self.menusView.setCornerRadius(cornerRadius: 30)
            self.usernameLabel.text = "主页"
            self.menuViewWidth.constant = 160

            self.view.layoutIfNeeded()
        } completion: { _ in
            self.menuIsShowing = false
        }

        if menuRecognizer != nil {
            view.addGestureRecognizer(menuRecognizer!)
        }
    }

    override var preferredFocusedView: UIView? {
        return leftCollectionView
    }

    struct PlayCommand: Decodable {
        let bvid: String
        let platform: String
        let id: String
    }

    struct PlayCommandRequest: Encodable {}

    var cancellableBag = Set<AnyCancellable>()
    var playedCommandIDs: [String] = []

    func startRequestPlayCommand() {
        Timer.publish(every: 5, tolerance: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.requestPlayCommand()
            }
            .store(in: &cancellableBag)
    }

    func requestPlayCommand() {
        guard let uid = ApiRequest.getToken()?.mid else { return }
        AF
            .request("https://cheers.musichelper.org/api/getPlayCommand?uid=\(uid)")
            .response { [weak self] response in
                guard let data = response.data,
                      let jsonDictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataJSON = jsonDictionary["data"] as? [String: Any],
                      let platform = dataJSON["platform"] as? String,
                      platform == "bilibili",
                      let bvid = dataJSON["bvid"] as? String,
                      let pid = dataJSON["pid"] as? String
                else {
                    print("DEBUG: no valid play command")
                    return
                }

                print("DEBUG: received play command: bvid=\(bvid), pid=\(pid)")
                self?.playVideo(bvid: bvid, pid: pid)
            }
    }

    private func playVideo(bvid: String, pid: String) {
        guard !playedCommandIDs.contains(pid) else { return }
        playedCommandIDs.append(pid)

        let aid = BvidConvertor.bv2av(bvid: bvid)

        let vc = VideoDetailViewController.create(aid: Int(aid), cid: 0)
        vc.present(from: self)
    }

    func setupData() {
        cellModels.append(CellModel(iconImage: UIImage(systemName: "person.badge.plus"), title: "关注", contentVC: FollowsViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "timelapse"), title: "推荐", contentVC: FeedViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "livephoto.play"), title: "热门", contentVC: HotViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "arrow.up.and.person.rectangle.portrait"), title: "排行榜", contentVC: RankingViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "magnifyingglass"), title: "搜索", contentVC: SearchContainerViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "star"), title: "收藏", contentVC: FavoriteViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "clock"), title: "历史记录", contentVC: HistoryViewController()))
        cellModels.append(CellModel(iconImage: UIImage(systemName: "gear"), title: "设置", contentVC: PersonalViewController.create()))

        let logout = CellModel(iconImage: UIImage(systemName: "figure.run"), title: "登出", autoSelect: false) {
            [weak self] in
            self?.actionLogout()
        }
        cellModels.append(logout)
    }

    func setViewController(vc: UIViewController) {
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        if var sidebarMenuPresentable = vc as? SidebarMenuPresentable {
            sidebarMenuPresentable.backMenuAction = { [weak self] in
                self?.showMensu()
            }
        }
        currentViewController = vc
        addChild(vc)
        contentView.addSubview(vc.view)
        vc.view.makeConstraintsToBindToSuperview()
        vc.didMove(toParent: self)

        BLAfter(afterTime: 0.3) {
            self.hiddenMensu()
        }
    }

    func reloadData() {
        (currentViewController as? RefreshableTab)?.reloadData()
    }

    func actionLogout() {
        let alert = UIAlertController(title: "确定登出？", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) {
            _ in
            WebRequest.logout {
                ApiRequest.logout { hasRemainingAccount in
                    if hasRemainingAccount {
                        AccountManager.shared.refreshActiveAccountProfile()
                    } else {
                        AppDelegate.shared.showLogin()
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

extension MenusViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BLMenuLineCollectionViewCell
        cell.titleLabel.text = cellModels[indexPath.item].title
        if let icon = cellModels[indexPath.item].iconImage {
            cell.iconImageView.image = icon.withRenderingMode(.alwaysTemplate)
        }
        cell.updateView()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellModels.count
    }
}

extension MenusViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = cellModels[indexPath.item]
        if let vc = model.contentVC {
            setViewController(vc: vc)
        }
        model.action?()
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // 检查新的焦点是否是UICollectionViewCell，失去焦点后隐藏菜单
        guard context.nextFocusedIndexPath != nil else {
            hiddenMensu()
            return
        }
    }
}
