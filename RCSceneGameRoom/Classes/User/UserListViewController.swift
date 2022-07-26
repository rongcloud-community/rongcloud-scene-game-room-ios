//
//  UserListViewController.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/14.
//

import UIKit
import RCSceneRoom


public protocol UserListViewControllerProtocol: AnyObject {
    func didClickedUser(userId: String, userList: UserListViewController)
}

public class UserListViewController: UIViewController {
    private let room: RCSceneRoom
    private weak var delegate: UserListViewControllerProtocol?
    
    private lazy var tableView: UITableView = {
        let instance = UITableView(frame: .zero, style: .plain)
        instance.backgroundColor = .clear
        instance.separatorStyle = .none
        instance.register(cellType: UserInfoCell.self)
        instance.dataSource = self
        instance.delegate = self
        return instance
    }()
    
    private lazy var emptyView = UsersEmptyView()
    
    private lazy var cancelButton: UIButton = {
        let instance = UIButton()
        instance.setImage(RCSCAsset.Images.whiteQuiteIcon.image, for: .normal)
        instance.addTarget(self, action: #selector(handleCancelClick), for: .touchUpInside)
        instance.sizeToFit()
        return instance
    }()
    
    private lazy var titleLabel: UILabel = {
        let instance = UILabel()
        instance.text = "用户列表"
        instance.textColor = .white
        return instance
    }()
    
    
    private var userlist = [RCSceneRoomUser]() {
        didSet {
            emptyView.isHidden = userlist.count > 0
        }
    }
    private var managers = [String]()
    
    
    public init(room: RCSceneRoom, delegate: UserListViewControllerProtocol) {
        self.delegate = delegate
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 108/255.0, green: 55/255.0, blue: 169/255.0, alpha: 1.0)
        
        view.addSubview(emptyView)
        view.addSubview(tableView)
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance.init()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 108/255.0, green: 55/255.0, blue: 169/255.0, alpha: 1.0)
            let effect = UIBlurEffect(style: .regular)
            appearance.backgroundEffect = effect
            appearance.shadowImage = UIImage.init()
            appearance.shadowColor = UIColor.clear
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.titleView = titleLabel

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-72.resize)
            make.width.height.equalTo(190.resize)
        }
        fetchRoomUserlist()
        fetchmanagers()
    }

    private func fetchRoomUserlist() {
        gameRoomService.roomUsers(roomId: room.roomId) { [weak self] result in
            switch result.map(RCSceneWrapper<[RCSceneRoomUser]>.self) {
            case let .success(wrapper):
                if let users = wrapper.data {
                    self?.userlist = users
                    self?.tableView.reloadData()
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    private func fetchmanagers() {
        gameRoomService.roomManagers(roomId: room.roomId) { [weak self] result in
            switch result.map(RCSceneWrapper<[RCSceneRoomUser]>.self) {
            case let .success(wrapper):
                if let users = wrapper.data {
                    self?.managers = users.map(\.userId)
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
        
    }
    
    @objc func handleCancelClick() {
        dismiss(animated: true, completion: nil)
    }

}

extension UserListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userlist.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: UserInfoCell.self)
        cell.updateCell(user: userlist[indexPath.row], hidesInvite: true)
        return cell
    }
}

extension UserListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = userlist[indexPath.row]
        guard user.userId != Environment.currentUserId else {
            return
        }
        delegate?.didClickedUser(userId: user.userId, userList: self)
    }
}


class UsersEmptyView: UIView {
    private lazy var imageView = UIImageView(image: RCSCAsset.Images.voiceRoomUsersEmptyIcon.image)
    private lazy var titleLabel = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(snp.bottom).offset(-32.resize)
        }
        titleLabel.text = "暂无用户"
        titleLabel.textColor = UIColor.white.alpha(0.5)
        titleLabel.font = UIFont.systemFont(ofSize: 16.resize)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
