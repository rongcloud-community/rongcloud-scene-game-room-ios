//
//  UsedSeatPopView.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/10.
//

import UIKit


enum MasterSeatUserAction {
    case forbiddenSeat
    case micState
    case leaveSeat

    var button: UIButton {
        switch self {
        case .forbiddenSeat:
            let instance = UIButton()
            instance.backgroundColor = RCSCAsset.Colors.hexCDCDCD.color.withAlphaComponent(0.2)
            instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            instance.setTitle("座位禁麦", for: .normal)
            instance.setTitle("取消禁麦", for: .selected)
            instance.setTitleColor(RCSCAsset.Colors.hexEF499A.color, for: .normal)
            instance.layer.cornerRadius = 4
            return instance
        case .micState:
            let instance = UIButton()
            instance.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            instance.setTitle("打开麦克风", for: .normal)
            instance.setTitle("关闭麦克风", for: .selected)
            instance.layer.cornerRadius = 4
            return instance
        case .leaveSeat:
            let instance = UIButton()
            instance.backgroundColor = RCSCAsset.Colors.hexCDCDCD.color.withAlphaComponent(0.2)
            instance.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            instance.setTitle("下麦围观", for: .normal)
            instance.layer.cornerRadius = 4
            return instance
        }
    }
}


class OwnerSeatPopView: UIView {
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
    
    private lazy var stackView: UIStackView = {
        let instance = UIStackView()
        instance.distribution = .fillEqually
        instance.axis = .vertical
        instance.spacing = 15
        return instance
    }()
    
  
    public var sheetActions: [UIButton]?
    
    init(actions: [UIButton]?) {
        super.init(frame: .zero)
        sheetActions = actions
        buildLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        popMenuClip(corners: [.topLeft, .topRight], cornerRadius: 22, centerCircleRadius: 37)
    }
    
    private func buildLayout() {
        addSubview(blurView)
        addSubview(avatarImageView)
        addSubview(nameLabel)
       
        if let sheetActions = self.sheetActions {
            for btn in sheetActions {
                stackView.addArrangedSubview(btn)
                btn.snp.makeConstraints { make in
                    make.height.equalTo(40)
                }
            }
        }
        addSubview(stackView)

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
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(15)
            $0.left.equalToSuperview().offset(30)
            $0.right.equalToSuperview().offset(-30)
        }
    }

    func updateView(user: RCSceneRoomUser) {
        avatarImageView.kf.setImage(with: URL(string: user.portraitUrl), placeholder: RCSCAsset.Images.defaultAvatar.image)
        nameLabel.text = user.userName
    }
}

extension UIView {
    func popMenuClip(corners: UIRectCorner, cornerRadius: CGFloat, centerCircleRadius: CGFloat) {
        let roundCornerBounds = CGRect(x: 0, y: centerCircleRadius, width: bounds.size.width, height: bounds.size.height - centerCircleRadius)
        let path = UIBezierPath(roundedRect: roundCornerBounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: (bounds.size.width/2) - centerCircleRadius, y: 0, width: centerCircleRadius * 2, height: centerCircleRadius * 2))
        path.append(ovalPath)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
