//
//  InviteSeatTableViewCell.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/11.
//

import UIKit
import Reusable

class InviteSeatTableViewCell: UITableViewCell, Reusable {
    private lazy var avatarImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.layer.cornerRadius = (48.resize)/2
        instance.clipsToBounds = true
        instance.image = RCSCAsset.Images.defaultAvatar.image
        return instance
    }()
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 17, weight: .medium)
        instance.textColor = .white
        return instance
    }()
    
    private lazy var inviteVoiceButton: UIButton = {
        let instance = UIButton()
        let color = UIColor(red: 236/255.0, green: 94/255.0, blue: 99/255.0, alpha: 1.0)
        instance.backgroundColor = color
        instance.titleLabel?.font = .systemFont(ofSize: 13)
        instance.setTitle("邀请上麦", for: .normal)
        instance.layer.cornerRadius = 5
        instance.addTarget(self, action: #selector(handleInviteVoiceClick), for: .touchUpInside)
        return instance
    }()
    
    
    private lazy var inviteGameButton: UIButton = {
        let instance = UIButton()
        let color = UIColor(red: 236/255.0, green: 94/255.0, blue: 99/255.0, alpha: 1.0)
        instance.backgroundColor = color
        instance.titleLabel?.font = .systemFont(ofSize: 13)
        instance.setTitle("邀请游戏", for: .normal)
        instance.layer.cornerRadius = 5
        instance.addTarget(self, action: #selector(handleInviteGameClick), for: .touchUpInside)
        return instance
    }()
    
    private lazy var lineView: UIView = {
        let instance = UIView()
        instance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return instance
    }()
    
    private var userId: String?
    var inviteVoiceCallback:((String) -> Void)?
    var inviteGameCallback:((String) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildLayout() {
        backgroundColor = .clear
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(inviteVoiceButton)
        contentView.addSubview(inviteGameButton)
        contentView.addSubview(lineView)
        
        
        inviteGameButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 70, height: 30))
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-15)
        }
        
        inviteVoiceButton.snp.makeConstraints {
            $0.size.equalTo(inviteGameButton)
            $0.centerY.equalToSuperview()
            $0.right.equalTo(inviteGameButton.snp_left).offset(-10)
        }
        
        nameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarImageView.snp.right).offset(12.resize)
            $0.right.lessThanOrEqualTo(inviteVoiceButton.snp.left).offset(-4)
            $0.centerY.equalToSuperview()
        }
        
        avatarImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(23.resize)
            $0.top.bottom.equalToSuperview().inset(8.resize)
            $0.size.equalTo(CGSize(width: 48.resize, height: 48.resize))
        }
        
        lineView.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.left.equalTo(avatarImageView.snp.right)
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    
    func updateCell(user: RCSceneRoomUser, loginUserRole: SceneRoomUserType, loginUserOnGame: Bool) {
        if loginUserRole == .creator || loginUserRole == .manager {
            if loginUserOnGame {
                inviteGameButton.isHidden = false
            } else {
                inviteGameButton.isHidden = true
                inviteVoiceButton.snp.remakeConstraints {
                    $0.size.equalTo(CGSize(width: 70, height: 30))
                    $0.centerY.equalToSuperview()
                    $0.right.equalToSuperview().offset(-15)
                }
            }
        } else { // 观众没有邀请上麦权限
            inviteVoiceButton.isHidden = true
            if loginUserOnGame {
                inviteGameButton.isHidden = false
            } else {
                inviteGameButton.isHidden = true
            }
        }
         
    
        userId = user.userId
        nameLabel.text = user.userName
        avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
    }
    
    @objc func handleInviteVoiceClick() {
        guard let id = userId else {
            return
        }
        inviteVoiceCallback?(id)
    }
    
    @objc func handleInviteGameClick() {
        guard let id = userId else {
            return
        }
        inviteGameCallback?(id)
    }
}
