//
//  RCSelectGameItemCellCollectionViewCell.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/4.
//

import UIKit
import RCSceneRoom

class RCSelectGameItemCell: UICollectionViewCell , Reusable {
    
    private lazy var iconImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = nil
        return instance
    }()
    private lazy var nameLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 12)
        instance.textColor = .white
        instance.text = " "
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
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        
        iconImageView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.size.equalTo(CGSize(width: 50.resize, height: 50.resize))
        }
        
        nameLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(iconImageView.snp.bottom).offset(8.resize)
            $0.bottom.equalToSuperview()
        }
    }
    
    public func updateCell(item: RCSceneGameResp) {
        iconImageView.kf.setImage(with: URL(string: item.thumbnail))
        nameLabel.text = item.gameName
    }
}
