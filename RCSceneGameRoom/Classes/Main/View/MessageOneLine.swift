//
//  MessageOneLine.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/27.
//

import UIKit
import RCSceneChatroomKit

class MessageOneLine: UIView, RCChatroomSceneEventProtocol {
    func cell(_ cell: UITableViewCell, didClickEvent eventId: String) {
        
        
    }
    
    private var messageArray = [RCChatroomSceneMessageProtocol]()

    
    private lazy var bgImageView: UIImageView = {
        let instance = UIImageView()
        instance.image = RCSCGameRoomAsset.messageBackground.image
        return instance
    }()
    
    private lazy var voiceMessageCell: RCChatroomSceneVoiceMessageCell = {
        return RCChatroomSceneVoiceMessageCell(style: .default, reuseIdentifier: "cell")
    }()
    
    private lazy var textMessageCell: RCChatroomSceneMessageCell = {
        return RCChatroomSceneMessageCell(style: .default, reuseIdentifier: "cell")
    }()
    
    private var sceneRoom = RCChatroomSceneView()
    
    private lazy var messageCell: RCChatroomSceneMessageView = {
        let messageView = sceneRoom.messageView
        messageView.tableView.rowHeight = 45
        messageView.tableView.isScrollEnabled = false
        return messageView
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(messageCell)
        
        messageCell.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    
    func add(message: RCChatroomSceneMessageProtocol) {
        messageArray.append(message)
        messageCell.addMessage(message)
        
        let row = IndexPath(row: messageArray.count - 1, section: 0)
        messageCell.tableView.scrollToRow(at:row, at: .bottom, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
