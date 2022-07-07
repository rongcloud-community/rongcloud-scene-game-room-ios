//
//  OnSeatUserOperationController.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/6.
//

import UIKit


protocol OnSeatUserOperationProtocol: AnyObject {
    func viewDidLoad(controller: OnSeatUserOperationController)
    func didClickedFollow(controller: OnSeatUserOperationController)
    func didClickedSendGift(controller: OnSeatUserOperationController)
    func didClickedPrivateChat(controller: OnSeatUserOperationController)
    func didClickedSetManager(controller: OnSeatUserOperationController)
}


class OnSeatUserOperationController: UIViewController {

    weak var delegate: OnSeatUserOperationProtocol?
    
    public var bottomBarButtons: [UIButton]?
    
    public var currentSeatUser: RCGameSeatUser
    
    public var isCurrentUserFollowed: Bool
    public var isCurrentUserManager: Bool
    
    private var canSetManager: Bool

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
    private lazy var sendMessageButton: UIButton = {
        let instance = UIButton()
        instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        instance.setTitle("发私信", for: .normal)
        instance.setTitleColor(RCSCAsset.Colors.hexEF499A.color, for: .normal)
        instance.backgroundColor = .clear
        instance.layer.cornerRadius = 22
        instance.layer.borderWidth = 1.0
        instance.layer.borderColor = RCSCAsset.Colors.hexEF499A.color.cgColor
        instance.addTarget(self, action: #selector(handleSendMessage), for: .touchUpInside)
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
    
    public init(bottomButtons: [UIButton]?, gameSeatUser: RCGameSeatUser, delegate: OnSeatUserOperationProtocol?, canSetManager: Bool) {
        self.bottomBarButtons = bottomButtons
        self.currentSeatUser = gameSeatUser
        self.delegate = delegate
        self.isCurrentUserFollowed = false
        
        self.canSetManager = canSetManager
        self.isCurrentUserManager = (gameSeatUser.role == .manager)
        super.init(nibName: nil, bundle: nil)

    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        fetchUserInfo()
        setupStackView()
        updateManageButton()
        self.delegate?.viewDidLoad(controller: self)
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
        guard let userId = currentSeatUser.userId else {
            return
        }
        RCSceneUserManager.shared.refreshUserInfo(userId: userId) { [weak self] user in
            guard let self = self else { return }
            self.avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
            self.isCurrentUserFollowed = user.isFollow
            self.updateFollowButton()
            self.nameLabel.text = user.userName
        }
        
    }
    
    func updateManageButton() {
        self.manageButton.isHidden = !self.canSetManager
        self.manageButton.isSelected = self.isCurrentUserManager
    }
    
    func updateFollowButton() {
        self.followButton.isSelected = self.isCurrentUserFollowed
    }
    
    
    private func buildLayout() {
        enableClickingDismiss()
        view.addSubview(container)
        container.addSubview(blurView)
        container.addSubview(avatarImageView)
        container.addSubview(nameLabel)
        container.addSubview(giftButton)
        container.addSubview(sendMessageButton)
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
        
        sendMessageButton.snp.makeConstraints { make in
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
            sendMessageButton.snp.remakeConstraints { make in
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
        bottomBarButtons?.forEach { button in
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func setManager() {
        self.delegate?.didClickedSetManager(controller: self)
    }

    @objc private func handleSendGift() {
        dismiss(animated: true) {
            self.delegate?.didClickedSendGift(controller: self)
        }
    }
    
    @objc private func handleSendMessage() {
        dismiss(animated: true) {
            self.delegate?.didClickedPrivateChat(controller: self)
        }
    }
    
    @objc private func handleFollow() {
        if self.isCurrentUserFollowed { return }
        self.delegate?.didClickedFollow(controller: self)
    }
}
