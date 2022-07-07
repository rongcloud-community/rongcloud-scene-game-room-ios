//
//  MessageBoardView.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/22.
//

import Foundation
import UIKit
import RCSceneRoom


public let messageBoardHeight = 320

class MessageBoardView: UIView {
    
    private let closedCallback:(() -> Void)?
    
    private var messageView: RCChatroomSceneMessageView
    
    
    private lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .regular)
        let instance = UIVisualEffectView(effect: effect)
        return instance
    }()
    
    public init(messageView: RCChatroomSceneMessageView, closed: @escaping (() -> Void)) {
        self.messageView = messageView
        self.closedCallback = closed
        super.init(frame: .zero)
        buildLayout()
    }
    
    public lazy var boardCloseButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = .clear
        instance.setBackgroundImage(RCSCGameRoomAsset.closeMsgBoard.image, for: .normal)
        instance.addTarget(self, action: #selector(boardClose), for: .touchUpInside)
        return instance
    }()
    
    
    public func show() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.snp.remakeConstraints {
                $0.left.right.bottom.equalToSuperview()
                $0.height.equalTo(messageBoardHeight)
            }
            self?.superview?.layoutIfNeeded()
        } completion: { _  in
        }
    }
    
    public func dissmiss() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.height.equalTo(messageBoardHeight)
                if let superView = self?.superview {
                    $0.top.equalTo(superView.snp.bottom).offset(messageBoardHeight)
                }
            }
            self?.superview?.layoutIfNeeded()
        } completion: { _  in
            
        }
        if let closedCallback = self.closedCallback {
            closedCallback()
        }
    }
    
    @objc private func boardClose(btn: UIButton) {
        dissmiss()
    }
    

    private func buildLayout() {
        layer.cornerRadius = 22
        clipsToBounds = true
//        backgroundColor = UIColor(red: 108/255.0, green: 55/255.0, blue: 169/255.0, alpha: 0.95)
        
        addSubview(blurView)
        addSubview(boardCloseButton)
        addSubview(messageView)
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        boardCloseButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(15)
            $0.right.equalToSuperview().offset(-10)
        }
        
        let safeInset = UIWindow.compatibleKeyWindow?.safeAreaInsets ?? UIEdgeInsets();
        
        messageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(15)
            $0.left.equalToSuperview()
            $0.right.equalTo(boardCloseButton.snp.left).offset(-50)
            $0.height.equalToSuperview().offset(-(safeInset.bottom + 60))
        }
        messageView.tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
