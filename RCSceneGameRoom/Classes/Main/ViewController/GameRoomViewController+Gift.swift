//
//  GameRoomViewController+Gift.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/21.
//

import SVProgressHUD

/// 用户进入房间礼物信息为空

extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupGiftModule() {
        setupModules()
        fetchGiftInfo()
    }
    
    private func fetchGiftInfo() {
        voiceRoomService.giftList(roomId: voiceRoomInfo.roomId) { [weak self] result in
            switch result {
            case let .success(value):
                print(value)
                guard
                    let info = try? JSONSerialization.jsonObject(with: value.data, options: .allowFragments),
                    let items = (info as? [String: Any])?["data"] as? [[String: Int]]
                else { return }
                self?.onFetchGiftInfo(items)
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func onFetchGiftInfo(_ items: [[String: Int]]) {
        var tmpValues = userGiftInfo
        items.forEach { item in
            item.forEach { key, value in
                tmpValues[key] = value
            }
        }
        userGiftInfo = tmpValues
    }
    
    @objc func handleGiftButtonClick() {
        let seatUsers = self.voiceRoomSeats.map { $0.userId ?? "" }
        let dependency = RCGameSceneGiftDependency(room: voiceRoomInfo,
                                                 seats: seatUsers)
        navigator(.gift(dependency: dependency, delegate: self))
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func like_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        handleGiftMessage(message.content)
    }
    
    private func handleGiftMessage(_ content: RCMessageContent?) {
        if let giftMessage = content as? RCChatroomGift {
            let value = userGiftInfo[giftMessage.targetId] ?? 0
            let increase = giftMessage.number * giftMessage.price
            userGiftInfo[giftMessage.targetId] = value + increase
        }
        else if let giftMessage = content as? RCChatroomGiftAll {
            let giftValue = giftMessage.number * giftMessage.price
            var giftValues = userGiftInfo
            self.voiceRoomSeats
                .filter { $0.userId != nil }
                .forEach { seatInfo in
                    let userId = seatInfo.userId!
                    let value = giftValues[userId] ?? 0
                    giftValues[userId] = value + giftValue
                }
            userGiftInfo = giftValues
        }
    }
}


extension GameRoomViewController: RCGameSceneGiftViewControllerDelegate {
    func userRealSeatIndex(userId: String) -> Int? {
        let gameUser = self.gameSeatUsers.filter { $0.userId == userId }
        return gameUser.first?.voiceSeatIndex
    }
    
    func roomManagerIds() -> [String] {
        [String]()
    }
    
    func gameSceneDidSendGift(message: RCMessageContent) {
        if let message = message as? RCChatroomSceneMessageProtocol {
            addMessageToView(message)
        }
        handleGiftMessage(message)
        fetchGiftInfo()
    }
}
 

extension GameRoomViewController: RCSceneGiftViewControllerDelegate {
    func didSendGift(message: RCMessageContent) {
        if let message = message as? RCChatroomSceneMessageProtocol {
            addMessageToView(message)
        }
        handleGiftMessage(message)
        fetchGiftInfo()
    }
}
 
