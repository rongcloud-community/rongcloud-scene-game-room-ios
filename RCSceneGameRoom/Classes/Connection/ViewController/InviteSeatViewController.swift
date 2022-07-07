//
//  InviteSeatViewController.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/10.
//

import UIKit
import RCSceneRoom


class InviteSeatViewController: UIViewController {
    private let roomId: String
    
    private lazy var tableView: UITableView = {
        let instance = UITableView(frame: .zero, style: .plain)
        instance.backgroundColor = .clear
        instance.separatorStyle = .none
        instance.register(cellType: InviteSeatTableViewCell.self)
        instance.dataSource = self
        return instance
    }()
    
    private lazy var emptyView = RCSceneRoomUsersEmptyView()
        
    private var userlist = [RCSceneRoomUser](){
        didSet {
            emptyView.isHidden = userlist.count > 0
        }
    }
    
    private let inviteVoiceCallback:((String) -> Void)
    private let inviteGameCallback:((String) -> Void)
    
    private let onSeatUserlist: [String]
    private let onGamePlayerlist: [String]
    
    private let gameCaptainId: String
    
    private let currentLoginUser = Environment.currentUserId
    private let loginUserRole: SceneRoomUserType
    
    init(roomId: String, loginUserRole: SceneRoomUserType, onSeatUserList: [String], onGamePlayerlist: [String], gameCaptainId: String, inviteVoiceCallback: @escaping ((String) -> Void), inviteGameCallback: @escaping ((String) -> Void)) {
        self.roomId = roomId
        
        self.loginUserRole = loginUserRole
        
        self.onSeatUserlist = onSeatUserList
        self.onGamePlayerlist = onGamePlayerlist
        
        self.gameCaptainId = gameCaptainId
        
        self.inviteVoiceCallback = inviteVoiceCallback
        self.inviteGameCallback = inviteGameCallback

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40.resize)
            make.width.height.equalTo(160.resize)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        fetchRoomUserlist()
    }
    
    private func buildLayout() {
        view.backgroundColor = RCSCAsset.Colors.hex03062F.color.withAlphaComponent(0.5)
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.left.bottom.right.equalToSuperview()
            $0.top.equalToSuperview().offset(220.resize)
        }
    }
    
    private func fetchRoomUserlist() {
        let seatUserIds = onSeatUserlist
        voiceRoomService.roomUsers(roomId: roomId) { [weak self] result in
            switch result.map(RCSceneWrapper<[RCSceneRoomUser]>.self) {
            case let .success(wrapper):
                if let users = wrapper.data, let self = self {
                    var showUserlist = [RCSceneRoomUser]()
                    
                    if self.loginUserRole == .creator || self.loginUserRole == .manager {
                        if self.onGamePlayerlist.contains(self.currentLoginUser) {
                            showUserlist = users.filter { !self.onGamePlayerlist.contains($0.userId) && $0.userId != self.currentLoginUser }
                        } else {
                            showUserlist = users.filter { !self.onSeatUserlist.contains($0.userId) && $0.userId != self.currentLoginUser }
                        }
                    } else {
                        if self.onGamePlayerlist.contains(self.currentLoginUser) &&
                            self.currentLoginUser == self.gameCaptainId
                        {
                            showUserlist = users.filter { !self.onGamePlayerlist.contains($0.userId) && $0.userId != self.currentLoginUser }
                        }
                    }
                    
                    self.userlist = showUserlist

                    // 当前登录用户已经上麦
                    self.tableView.reloadData()
                }
            case .failure(_): break
                
            }
        }
    }
}

extension InviteSeatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: InviteSeatTableViewCell.self)
        let user = userlist[indexPath.row]
        let loginUserOnGame = self.onGamePlayerlist.contains(self.currentLoginUser)
        cell.updateCell(user: user, loginUserRole: self.loginUserRole, loginUserOnGame: loginUserOnGame)
        cell.inviteVoiceCallback = {
            [weak self] userId in
            self?.inviteVoiceCallback(userId)
        }
        cell.inviteGameCallback = {
            [weak self] userId in
            self?.inviteGameCallback(userId)
        }
        return cell
    }
}
