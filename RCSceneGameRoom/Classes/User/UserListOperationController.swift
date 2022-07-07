//
//  UserListOperationController.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/14.
//

import UIKit
import Moya
import RCSceneRoom

public protocol UserListOperationProtocol: AnyObject {
    func didChangeManager(userId: String, isManager: Bool)
    func userDidFollowed(userId: String)
    func sendGiftTo(userId: String)
    func privateChatTo(userId: String)
    
    // bottom buttons action to delegate
    func pickDownUser(userId: String)
    func lockSeatFor(userId: String)
    func muteSeatFor(userId: String)
    func kickOutUser(userId: String)
    func inviteGame(userId: String)
    func kickOutGame(userId: String)
    func inviteVoiceSeatFor(userId: String)
    func changeUserToSeat(userId: String)
    
    func loginUserIsCaptain() -> Bool
    func userIsManager(userId: String) -> Bool
    func loginUserOnVoiceSeat() -> Bool
    func getCurrentGameState() -> RCGameState
}

class UserListOperationController: UIViewController {
    
    private weak var delegate: UserListOperationProtocol?
    
    let pickDownBtn = OnSeatUserAction.pickDown.button
    let lockSeatBtn = OnSeatUserAction.lockSeat.button
    let muteBtn = OnSeatUserAction.mute.button
    let kickOutBtn = OnSeatUserAction.kickOut.button
    let inviteVoiceBtn = OnSeatUserAction.inviteVoice.button
    let inviteGameBtn = OnSeatUserAction.inviteGame.button
    let kickOutGameBtn = OnSeatUserAction.kickOutGame.button
    let changeMeBtn = OnSeatUserAction.changeEnterSeat.button
    
    private var bottomBarButtons: [UIButton]?
    
    private var currentUserId: String
    private var loginUserType: SceneRoomUserType

    private var currentRoomInfo: RCSceneRoom
    private var voiceSeatInfo: RCVoiceSeatInfo?

    private var isCurrentUserFollowed: Bool
    private var isCurrentUserManager: Bool
    private var isUserInGame: Bool

    private lazy var avatarImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.image = RCSCAsset.Images.defaultAvatar.image
        instance.layer.cornerRadius = 28
        instance.layer.masksToBounds = true
        return instance
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .regular)
        let instance = UIVisualEffectView(effect: effect)
        return instance
    }()
    
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 17, weight: .medium)
        instance.textColor = .white
        return instance
    }()
    
    private lazy var giftButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = RCSCAsset.Colors.hexCDCDCD.color.withAlphaComponent(0.2)
        instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        instance.setTitle("送礼物", for: .normal)
        instance.setTitleColor(UIColor.white, for: .normal)
        instance.layer.cornerRadius = 22
        instance.backgroundColor = RCSCAsset.Colors.hexEF499A.color
        instance.addTarget(self, action: #selector(handleSendGift), for: .touchUpInside)
        return instance
    }()
    
    private lazy var privateChatButton: UIButton = {
        let instance = UIButton()
        instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        instance.setTitle("发私信", for: .normal)
        instance.setTitleColor(RCSCAsset.Colors.hexEF499A.color, for: .normal)
        instance.backgroundColor = .clear
        instance.layer.cornerRadius = 22
        instance.layer.borderWidth = 1.0
        instance.layer.borderColor = RCSCAsset.Colors.hexEF499A.color.cgColor
        instance.addTarget(self, action: #selector(handlePrivateChat), for: .touchUpInside)
        return instance
    }()
    
    private lazy var followButton: UIButton = {
        let instance = UIButton()
        instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        instance.setTitle("关注", for: .normal)
        instance.setTitle("已关注", for: .selected)
        instance.setTitleColor(RCSCAsset.Colors.hexEF499A.color, for: .normal)
        instance.backgroundColor = .clear
        instance.layer.cornerRadius = 22
        instance.layer.borderWidth = 1.0
        instance.layer.borderColor = RCSCAsset.Colors.hexEF499A.color.cgColor
        instance.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        return instance
    }()
    
    
    private lazy var manageButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        instance.titleLabel?.font = .systemFont(ofSize: 13)
        instance.setTitle("设为管理", for: .normal)
        instance.setTitle("撤回管理", for: .selected)
        instance.setImage(RCSCAsset.Images.emptyStar.image, for: .normal)
        instance.setImage(RCSCAsset.Images.fullStar.image, for: .selected)
        instance.setTitleColor(UIColor(hexInt: 0xdfdfdf), for: .normal)
        instance.addTarget(self, action: #selector(setManager), for: .touchUpInside)
        instance.centerTextAndImage(spacing: 5)
        return instance
    }()
    
    private lazy var container: UIView = {
        let instance = UIView()
        instance.backgroundColor = .clear
        return instance
    }()
    
    private lazy var stackView: UIStackView = {
        let instance = UIStackView()
        instance.distribution = .fillEqually
        instance.backgroundColor = RCSCAsset.Colors.hex03062F.color.withAlphaComponent(0.16)
        return instance
    }()
    
    
    public init(userId: String, roomInfo: RCSceneRoom, delegate: UserListOperationProtocol?, loginUserType: SceneRoomUserType, voiceSeatInfo: RCVoiceSeatInfo?, userInGame: Bool) {
        self.currentUserId = userId
        self.currentRoomInfo = roomInfo
        self.loginUserType = loginUserType
        self.voiceSeatInfo = voiceSeatInfo
        self.isUserInGame = userInGame
        self.delegate = delegate
        self.isCurrentUserFollowed = false
        self.isCurrentUserManager = false
        super.init(nibName: nil, bundle: nil)

    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupStackView()
        buildLayout()
        fetchUserInfo()
        addButtonActions()
        
        if let seatInfo = voiceSeatInfo {
            lockSeatBtn.isSelected = (seatInfo.status == .locking)
            muteBtn.isSelected = seatInfo.isMuted
        }
    }
    
    private func addButtonActions() {
        pickDownBtn.addTarget(self, action: #selector(handlePickDownUser), for: .touchUpInside)
        lockSeatBtn.addTarget(self, action: #selector(handleLockSeat), for: .touchUpInside)
        muteBtn.addTarget(self, action: #selector(handleMuteSeat), for: .touchUpInside)
        kickOutBtn.addTarget(self, action: #selector(handleKickOut), for: .touchUpInside)
        inviteGameBtn.addTarget(self, action: #selector(handleInviteGame), for: .touchUpInside)
        kickOutGameBtn.addTarget(self, action: #selector(handleKickOutGame), for: .touchUpInside)

        inviteVoiceBtn.addTarget(self, action: #selector(handleInviteVoice), for: .touchUpInside)
        changeMeBtn.addTarget(self, action: #selector(handleChangeMeToSeat), for: .touchUpInside)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.popMenuClip(corners: [.topLeft, .topRight], cornerRadius: 22, centerCircleRadius: 37)
        manageButton.roundCorners(corners: [.bottomLeft, .topRight], radius: 22)
        bottomBarButtons?.forEach { button in
            button.alignImageAndTitleVertically(padding: 8)
        }
    }
    
    private func fetchUserInfo() {
        RCSceneUserManager.shared.refreshUserInfo(userId: currentUserId) { [weak self] user in
            guard let self = self else { return }
            self.avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
            self.followButton.isSelected = user.isFollow
            self.isCurrentUserFollowed = user.isFollow
            self.nameLabel.text = user.userName
        }
        
        gameRoomService.roomManagers(roomId: currentRoomInfo.roomId) { [weak self] result in
            switch result.map(managersWrapper.self) {
            case let .success(wrapper):
                guard let self = self else { return }
                let managers = wrapper.data ?? []
                let isManager = managers.map(\.userId).contains(self.currentUserId)
                self.isCurrentUserManager = isManager
                self.manageButton.isSelected = isManager
            case let.failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    
    private func buildLayout() {
        enableClickingDismiss()
        view.addSubview(container)
        container.addSubview(blurView)
        container.addSubview(avatarImageView)
        container.addSubview(nameLabel)
        container.addSubview(giftButton)
        container.addSubview(privateChatButton)
        container.addSubview(followButton)
        container.addSubview(stackView)
        container.addSubview(manageButton)
        
        container.snp.makeConstraints {
            $0.left.bottom.right.equalToSuperview()
        }
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(9)
            make.size.equalTo(CGSize(width: 56, height: 56))
            make.centerX.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        giftButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18.resize)
            make.height.equalTo(44.resize)
            make.width.equalTo(104.resize)
            make.top.equalTo(nameLabel.snp.bottom).offset(30.resize)
        }
        
        privateChatButton.snp.makeConstraints { make in
            make.size.equalTo(giftButton)
            make.centerY.equalTo(giftButton)
            make.centerX.equalToSuperview()
        }
        
        followButton.snp.makeConstraints { make in
            make.size.equalTo(giftButton)
            make.centerY.equalTo(giftButton)
            make.right.equalToSuperview().inset(18.resize)
        }
        
        if let bottomBarButtons = self.bottomBarButtons {
            stackView.snp.makeConstraints {
                $0.top.equalTo(giftButton.snp.bottom).offset(25)
                $0.height.equalTo(135)
                $0.left.right.equalToSuperview()
                $0.bottom.equalToSuperview()
            }
        } else {
            privateChatButton.snp.remakeConstraints { make in
                make.size.equalTo(giftButton)
                make.centerY.equalTo(giftButton)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(25)
            }
        }
        
        manageButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(37)
            make.right.equalToSuperview()
            make.size.equalTo(CGSize(width: 114, height: 45))
        }
    }
    
    
    private func setupStackView() {
        if loginUserType == .creator {  // 当前登陆用户是房主
            if let seatInfo = voiceSeatInfo { // 被点击的当前用户已上麦
                var actions = [pickDownBtn, lockSeatBtn, muteBtn, kickOutBtn]
                if let delegate = self.delegate, delegate.loginUserIsCaptain() { // 当前登陆用户又是队长
                    if delegate.getCurrentGameState() != .PLAYING {
                        if isUserInGame { // 麦上用户加入游戏
                            actions.append(kickOutGameBtn)
                        } else {
                            actions.append(inviteGameBtn)
                        }
                    }
                }
                bottomBarButtons = actions
            } else { // 点击的用户未上麦
                bottomBarButtons = [inviteVoiceBtn, kickOutBtn]
            }
        
        } else if loginUserType == .manager { // 当前设备登陆用户是管理员
            manageButton.isHidden = true
            if currentUserId == self.currentRoomInfo.userId  { // 点击用户是房主或管理
                if let delegate = self.delegate, delegate.loginUserIsCaptain() {
                    if delegate.getCurrentGameState() != .PLAYING {
                        if isUserInGame { // 麦上用户加入游戏
                            bottomBarButtons = [kickOutGameBtn]
                        } else {
                            bottomBarButtons = [inviteGameBtn]
                        }
                    }
                }
            } else if let delegate = self.delegate, delegate.userIsManager(userId: currentUserId)  { // 点击用户是管理员
                if let delegate = self.delegate, delegate.loginUserIsCaptain() {
                    if delegate.getCurrentGameState() != .PLAYING {
                        if isUserInGame { // 麦上用户加入游戏
                            bottomBarButtons = [kickOutGameBtn]
                        } else {
                            bottomBarButtons = [inviteGameBtn]
                        }
                    }
                }
            } else { // 点击用户是普通成员
                if let delegate = self.delegate, delegate.loginUserOnVoiceSeat() { // 当前登陆用户已上麦
                    var actions = [UIButton]()
                    if let seatInfo = voiceSeatInfo { // 被点击用户已上麦
                        actions.append(pickDownBtn)
                    } else {
                        if delegate.getCurrentGameState() != .PLAYING {
                            actions.append(inviteVoiceBtn)
                        }
                    }
                
                    actions.append(kickOutBtn)
                    
                    if let delegate = self.delegate, delegate.loginUserIsCaptain() { // 当前登陆用户队长
                        if delegate.getCurrentGameState() != .PLAYING {
                            if isUserInGame { // 麦上用户加入游戏
                                actions.append(kickOutGameBtn)
                            } else {
                                actions.append(inviteGameBtn)
                            }
                        }
                    }
                    bottomBarButtons = actions
                } else { // 当前登陆用户未上麦
                    if let seatInfo = voiceSeatInfo { // 被点击用户已上麦
                        bottomBarButtons = [pickDownBtn, changeMeBtn, kickOutBtn]
                    } else { // 未上麦 （邀请上麦 踢出房间）
                        bottomBarButtons = [inviteVoiceBtn, kickOutBtn]
                    }
                }
            }
        } else { // 当前设备登陆用户是普通人  （上头像 下昵称 下 送礼物 发私信 关注 三个按钮）
            manageButton.isHidden = true
            if let delegate = self.delegate, delegate.loginUserIsCaptain() {
                if delegate.getCurrentGameState() != .PLAYING {
                    if isUserInGame { // 麦上用户加入游戏
                        bottomBarButtons = [kickOutGameBtn]
                    } else {
                        bottomBarButtons = [inviteGameBtn]
                    }
                }
            }
        }
    
        bottomBarButtons?.forEach { button in
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func setManager() {
        let toSet = !self.isCurrentUserManager
        gameRoomService.setRoomManager(roomId: currentRoomInfo.roomId, userId: currentUserId, isManager: toSet) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(res):
                if res.validate() {
                    self.isCurrentUserManager = toSet
                    self.manageButton.isSelected = toSet
                    self.delegate?.didChangeManager(userId: self.currentUserId, isManager: toSet)
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }

    @objc private func handleSendGift() {
        dismiss(animated: true) {
            self.delegate?.sendGiftTo(userId: self.currentUserId)
        }
    }
    
    @objc private func handlePrivateChat() {
        dismiss(animated: true) {
            self.delegate?.privateChatTo(userId: self.currentUserId)
        }
    }
    
    @objc private func handleFollow() {
        if self.isCurrentUserFollowed { return }
        gameRoomService.follow(userId: currentUserId) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(res):
                if res.validate() {
                    self.isCurrentUserFollowed = true
                    self.followButton.isSelected = true
                    self.delegate?.userDidFollowed(userId: self.currentUserId)
                } else {
                    SVProgressHUD.showError(withStatus: "关注请求失败")
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    
    @objc private func handlePickDownUser() {
        dismiss(animated: true) {
            self.delegate?.pickDownUser(userId: self.currentUserId)
        }
    }
    
    @objc private func handleLockSeat() {
        dismiss(animated: true) {
            self.delegate?.lockSeatFor(userId: self.currentUserId)
        }
    }
    
    @objc private func handleMuteSeat() {
        dismiss(animated: true) {
            self.delegate?.muteSeatFor(userId: self.currentUserId)
        }
    }
    
    @objc private func handleKickOut() {
        dismiss(animated: true) {
            self.delegate?.kickOutUser(userId: self.currentUserId)
        }
    }
    
    @objc private func handleInviteGame() {
        dismiss(animated: true) {
            self.delegate?.inviteGame(userId: self.currentUserId)
        }
    }
    
    @objc private func handleKickOutGame() {
        dismiss(animated: true) {
            self.delegate?.kickOutGame(userId: self.currentUserId)
        }
    }
    
    @objc private func handleInviteVoice() {
        dismiss(animated: true) {
            self.delegate?.inviteVoiceSeatFor(userId: self.currentUserId)
        }
    }
    
    
    @objc private func handleChangeMeToSeat() {
        dismiss(animated: true) {
            self.delegate?.changeUserToSeat(userId: self.currentUserId)
        }
    }
    
}
