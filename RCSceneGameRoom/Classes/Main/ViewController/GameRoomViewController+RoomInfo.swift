//
//  GameRoomViewController+RoomInfo.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/21.
//

import SVProgressHUD
import RCSceneRoom
import UIKit

extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
        roomInfoView.delegate = self
    }
    
    @_dynamicReplacement(for: kvRoomInfo)
    private var inner_kvRoomInfo: RCVoiceRoomInfo? {
        get {
            return kvRoomInfo
        }
        set {
            kvRoomInfo = newValue
            if let info = newValue {
                updateRoomInfo(info: info)
            }
        }
    }
    
    private func updateRoomInfo(info: RCVoiceRoomInfo) {
        voiceRoomInfo.roomName = info.roomName
        roomState.isLockAll = info.isLockAll
        roomState.isMuteAll = info.isMuteAll
        roomInfoView.updateRoom(info: voiceRoomInfo)
    }
}

extension GameRoomViewController: RoomInfoViewClickProtocol {
    func didFollowRoomUser(_ follow: Bool) {
        RCSceneUserManager.shared.refreshUserInfo(userId: voiceRoomInfo.userId) { followUser in
            guard follow else { return }
            RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { [weak self] user in
                let message = RCChatroomFollow()
                message.userInfo = user.rcUser
                message.targetUserInfo = followUser.rcUser
                ChatroomSendMessage(message) { result in
                    switch result {
                    case .success:
                        self?.addMessageToView(message)
                    case .failure(let error):
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func roomInfoDidClick() {
        navigator(.userlist(room: voiceRoomInfo, delegate: self))
    }
}


extension GameRoomViewController: UserListViewControllerProtocol {
    func didClickedUser(userId: String, userList: UserListViewController)  {
        let voiceSeatInfo = self.voiceRoomSeats.filter { $0.userId == userId }.first
        let userInGame = self.onPlaySeatUsers.contains(userId)
        
        let vc = UserListOperationController(userId: userId, roomInfo: voiceRoomInfo, delegate: self, loginUserType: currentUserRole(), voiceSeatInfo: voiceSeatInfo, userInGame: userInGame)
        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .popover
        userList.present(vc, animated: true)
        
        self.userViewPopListVc = userList
    }
}

extension GameRoomViewController: UserListOperationProtocol {
    func userIsManager(userId: String) -> Bool {
        return self.managers.map(\.userId).contains(userId)
    }
    
    func getCurrentGameState() -> RCGameState {
        return self.currentGameState
    }
    
    func loginUserOnVoiceSeat() -> Bool {
        return self.isSitting()
    }
    
    func loginUserIsCaptain() -> Bool {
        return self.currentLoginUser() == self.captainUserId
    }
    
    func sendGiftTo(userId: String) {
        let seatUsers = self.voiceRoomSeats.map { $0.userId ?? "" }
        let dependency = RCSceneGiftDependency(room: voiceRoomInfo,
                                               seats: seatUsers,
                                               userIds: [userId])

        let vc = RCSceneGiftViewController(dependency: dependency, delegate: self)
        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .popover
        vc.view.backgroundColor = .clear
        self.userViewPopListVc?.present(vc, animated: true)
    }
    
    func privateChatTo(userId: String) {
        if let userListVc = self.userViewPopListVc {
            ChatViewController.presenting(userListVc, userId: userId)
        }
    }
    
    
    func didChangeManager(userId: String, isManager: Bool) {
        let message = isManager ? "已设为管理员" : "已撤回管理员"
        SVProgressHUD.showSuccess(withStatus: message)
        RCSceneUserManager.shared.fetchUserInfo(userId: userId) { user in
            let event = RCChatroomAdmin()
            event.userId = user.userId
            event.userName = user.userName
            event.isAdmin = isManager
            self.chatroomSendMessage(event)
        }
        // 触发 sort seat 重新排列麦位
        self.fetchManagers()
    }
    
    func userDidFollowed(userId: String) {
        RCSceneUserManager.shared.refreshUserInfo(userId: userId) { followUser in
            RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { [weak self] user in
                let message = RCChatroomFollow()
                message.userInfo = user.rcUser
                message.targetUserInfo = followUser.rcUser
                self?.chatroomSendMessage(message)
            }
        }
    }
    
    
    func pickDownUser(userId: String) {
        RCVoiceRoomEngine.sharedInstance().kickUser(fromSeat: userId) {
            SVProgressHUD.showSuccess(withStatus: "下麦通知成功")
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "下麦通知失败")
        }
    }
    
    func lockSeatFor(userId: String) {
        if let voiceSeatIndex = self.voiceRoomSeats.firstIndex { $0.userId == userId }  {
            let voiceSeatInfo = self.voiceRoomSeats[voiceSeatIndex]
            let toSet = !(voiceSeatInfo.status == .locking)
            RCVoiceRoomEngine.sharedInstance().lockSeat(UInt(voiceSeatIndex), lock: toSet) {
                self.lockSeatBtn.isSelected = toSet
            } error: { errCode, msg in
                
            }
        }
    }
    
    func muteSeatFor(userId: String) {
        if let voiceSeatIndex = self.voiceRoomSeats.firstIndex { $0.userId == userId } {
            let voiceSeatInfo = self.voiceRoomSeats[voiceSeatIndex]
            let toSet = !voiceSeatInfo.isMuted
            RCVoiceRoomEngine.sharedInstance().muteSeat(UInt(voiceSeatIndex), mute: toSet) {
                self.muteBtn.isSelected = toSet
                if toSet {
                    SVProgressHUD.showSuccess(withStatus: "此麦位已禁麦")
                } else {
                    SVProgressHUD.showSuccess(withStatus: "此麦位取消禁麦")
                }
            } error: { code, msg in
                
            }
        }
    }
    
    func kickOutUser(userId: String) {
        RCVoiceRoomEngine.sharedInstance().kickUser(fromRoom: userId) {
            RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { user in
                RCSceneUserManager.shared.fetchUserInfo(userId: userId) { targetUser in
                    let event = RCChatroomKickOut()
                    event.userId = user.userId
                    event.userName = user.userName
                    event.targetId = targetUser.userId
                    event.targetName = targetUser.userName
                    self.chatroomSendMessage(event)
                }
            }
        } error: { code, msg in
            
        }
    }
    
    func inviteGame(userId: String) {
        VoiceRoomNotification.inviteJoinGame.send(content: userId)
    }
    
    func kickOutGame(userId: String) {
        RCGameEngine.shared().kickPlayer(userId) { _,_,_ in }
    }
    
    func inviteVoiceSeatFor(userId: String) {
        if isSitting(userId) {
            return SVProgressHUD.showError(withStatus: "用户已经在麦位上")
        }
        guard hasEmptySeat() else {
            SVProgressHUD.showError(withStatus: "麦位已满")
            return
        }
        RCVoiceRoomEngine.sharedInstance().pickUser(toSeat: userId) {
            SVProgressHUD.showSuccess(withStatus: "已邀请上麦")
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "邀请连麦发送失败")
        }
    }
    
    func changeUserToSeat(userId: String) {
        RCVoiceRoomEngine.sharedInstance().kickUser(fromSeat: userId) {
            SVProgressHUD.showSuccess(withStatus: "下麦通知成功")
            if !self.isSitting() { // 换当前用户上麦
                self.enterSeatIfAvailable()
            }
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "下麦通知失败")
        }
    }
}
