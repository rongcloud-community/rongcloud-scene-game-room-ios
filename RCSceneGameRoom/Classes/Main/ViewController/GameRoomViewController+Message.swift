//
//  GameRoomViewController+Message.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/22.
//

import SVProgressHUD

struct ChatroomError: Error, LocalizedError {
    let msg: String
    
    init(_ msg: String) {
        self.msg = msg
    }
    
    var errorDescription: String? {
        return msg
    }
}

func ChatroomSendMessage(_ content: RCMessageContent,
                         result:((Result<Int, ChatroomError>) -> Void)? = nil)
{
    guard let room = SceneRoomManager.shared.currentRoom else {
        result?(.failure(ChatroomError("没有加入房间")))
        return
    }
    RCChatroomMessageCenter.sendChatMessage(room.roomId, content: content) { code, mId in
        if code == .RC_SUCCESS {
            result?(.success(mId))
        } else {
            result?(.failure(ChatroomError("消息发送失败：\(code.rawValue)")))
        }
    }
}



extension GameRoomViewController {

    @_dynamicReplacement(for: setupModules)
    private func setupChatModule() {
        setupModules()
        msgBoardOpenButton.addTarget(self, action: #selector(boardOpen), for: .touchUpInside)

    }
    
    @objc private func boardOpen(btn: UIButton) {
        self.msgBoardOpenButton.isHidden = true
        self.messageLabel.isHidden = true
        self.msgBoardView.show()
    }
    
    
    func addMessageToView(_ message : RCChatroomSceneMessageProtocol) {
        messageLabel.add(message: message)
        messageView.addMessage(message)
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func chat_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        guard message.conversationType == .ConversationType_PRIVATE else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.messageButton.refreshMessageCount()
        }
    }
    
    
    func chatroomSendMessage(_ content: RCMessageContent)
    {
        guard let roomId = SceneRoomManager.shared.currentRoom?.roomId else {
            SVProgressHUD.showError(withStatus: "没有加入房间")
            return
        }
        RCChatroomMessageCenter.sendChatMessage(roomId, content: content) { code, mId in
            if code == .RC_SUCCESS {
                if let message = content as? RCChatroomSceneMessageProtocol {
                    self.addMessageToView(message)
                }
            } else {
                let msg = "消息发送失败：\(code.rawValue)"
                SVProgressHUD.showError(withStatus: msg)
            }
        }
    }

    
}
