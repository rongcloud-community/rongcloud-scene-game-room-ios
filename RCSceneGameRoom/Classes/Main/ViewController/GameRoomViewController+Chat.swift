//
//  GameRoomViewController+Chat.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import UIKit
import RCSceneRoom

extension GameRoomViewController {
    @_dynamicReplacement(for: managers)
    private var chat_managers: [RCSceneRoomUser] {
        get {
            return managers
        }
        set {
            managers = newValue
            messageView.tableView.reloadData()
        }
    }
    
    @_dynamicReplacement(for: setupModules)
    private func setupChatModule() {
        setupModules()
        messageView.setEventDelegate(self)
        addConstMessages()
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func chat_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        guard message.conversationType == .ConversationType_CHATROOM else { return }
        guard let rawMessage = message.content as? RCChatroomSceneMessageProtocol else { return }
        
        if let barrageMsg = message.content as? RCChatroomBarrage {
            if let onKeyword = self.onKeyword {
                if barrageMsg.content == onKeyword {
                    var mark = ""
                    onKeyword.map { _ in mark.append("*")}
                    let wordMsg = RCGameMessage(attributedMessage: NSAttributedString(string: mark))
                    addMessageToView(wordMsg)
                    return
                }
            }
        }
        
        addMessageToView(rawMessage)
    }
    
    private func addConstMessages() {
        let welcome = RCTextMessage(content: "欢迎来到\(voiceRoomInfo.roomName)")
        welcome.extra = "welcome"
        addMessageToView(welcome)
        let statement = RCTextMessage(content: "感谢使用融云RTC游戏房，请遵守相关法规，不要传播低俗、暴力等不良信息。欢迎您把使用过程中的感受反馈与我们。")
        statement.extra = "statement"
        addMessageToView(statement)
    }
}

extension GameRoomViewController: RCChatroomSceneEventProtocol {
    func cell(_ cell: UITableViewCell, didClickEvent eventId: String) {

    }
}

extension GameRoomViewController {
    func sendJoinRoomMessage() {
        RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { user in
            let event = RCChatroomEnter()
            event.userId = user.userId
            event.userName = user.userName
            self.chatroomSendMessage(event)
        }
    }
}
