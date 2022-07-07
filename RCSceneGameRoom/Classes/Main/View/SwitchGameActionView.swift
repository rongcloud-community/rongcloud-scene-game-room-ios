//
//  SwitchGameActionView.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/18.
//

import UIKit

class SwitchGameActionView: UIButton {
    
    private lazy var backGroundImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleToFill
        var image = RCSCGameRoomAsset.switchGameBackgroud.image
        let leftCapWidth = image.size.width * 0.5;
        let topCapHeight = image.size.height * 0.5;
        image = image.stretchableImage(withLeftCapWidth: Int(leftCapWidth), topCapHeight: Int(topCapHeight))
        instance.image = image
        return instance
    }()
    
    
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 11)
        instance.textColor = .white
        return instance
    }()
    
    
    private lazy var iconImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCGameRoomAsset.switchGameDownFlag.image
        return instance
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildLayout() {
        self.subviews.map { $0.removeFromSuperview() }
        
        addSubview(backGroundImageView)
        addSubview(iconImageView)
        addSubview(nameLabel)
        
        backGroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-5)
            $0.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(5)
            $0.centerY.equalToSuperview()
            $0.right.equalTo(iconImageView.snp_left).offset(-3)
        }
       
    }
    
    public func addTarget(_ target: Any, action: Selector) {
        addTarget(target, action: action, for: .touchUpInside)
    }
    
    public func update(game: String?) {
        guard let game = game else { return }
        nameLabel.text = game
    }
    
}
