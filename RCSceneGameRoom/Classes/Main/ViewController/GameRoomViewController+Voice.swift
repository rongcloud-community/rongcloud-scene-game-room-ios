//
//  GameRoomViewController+Engine.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
    }
    
    private func handleReceivePickSeat(from: String) {
        if let prevAlert = self.inviteVoiceAlert {
            return
        } else {
            var inviter = "房主"
            if managers.map(\.userId).contains(from) {
                inviter = "管理员"
            }
            let alertVC = UIAlertController(title: "是否同意上麦", message: "您被\(inviter)邀请上麦，是否同意？", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
                self.inviteVoiceAlert = nil
                self.enterSeatIfAvailable()
                VoiceRoomNotification.agreeManagePick.send(content: from)
            }))
            alertVC.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { _ in
                self.inviteVoiceAlert = nil
                VoiceRoomNotification.rejectManagePick.send(content: from)
            }))
            
            if let fm = self.floatingManager, fm.showing {
                UIApplication.shared.keyWindow()?.rootViewController?.present(alertVC, animated: true)
            } else {
                topmostController().present(alertVC, animated: true)
            }
            self.inviteVoiceAlert = alertVC
        }
    
    }
}

//MARK: - Voice Room Delegate
extension GameRoomViewController: RCVoiceRoomDelegate {
    func roomDidOccurError(_ code: RCVoiceRoomErrorCode) {
        if code == .syncRoomInfoFailed {
            SVProgressHUD.showError(withStatus: "房间初始化信息失败，请关闭房间重新创建")
        }
    }
    
    func roomKVDidReady() {
        roomInfoView.updateRoomUserNumber()
    }
    
    func roomInfoDidUpdate(_ roomInfo: RCVoiceRoomInfo) {
        if let currentRoomInfo = kvRoomInfo {
            if currentRoomInfo.seatCount != roomInfo.seatCount {
                
            }
        }
        
        kvRoomInfo = roomInfo
        print("roomInfoDidUpdate is \((kvRoomInfo))")
    }
    
    
    func userDidEnterSeat(_ seatIndex: Int, user userId: String) {
        print("userDidEnterSeat is \((seatIndex,userId))")
    }
    
    func seatInfoDidUpdate(_ seatInfolist: [RCVoiceSeatInfo]) {
        voiceRoomSeats = seatInfolist
        fetchManagers()
        print("seatinlist is \(voiceRoomSeats)")
        
        let isDisableMic = RCVoiceRoomEngine.sharedInstance().isDisableAudioRecording()
        micStateButton.isSelected = isDisableMic
    }
    
 
    
    func userDidLeaveSeat(_ seatIndex: Int, user userId: String) {
        
    }
    
    func seatDidMute(_ index: Int, isMute: Bool) {
    
    }
    
    func seatDidLock(_ index: Int, isLock: Bool) {
    }
    
    
    func userDidEnter(_ userId: String) {
        roomInfoView.updateRoomUserNumber()
    }
    
    func userDidExit(_ userId: String) {
        roomInfoView.updateRoomUserNumber()
    }
    

    func seatSpeakingStateChanged(_ speaking: Bool, at index: Int, audioLevel level: Int) {
        if let speakingIndex = self.gameSeatUsers.firstIndex { $0.voiceSeatIndex == index } {
            if let cell = collectionView.cellForItem(at: IndexPath(item: Int(speakingIndex), section: 0)) as? SeatUserViewCell {
                cell.setSpeakingState(isSpeaking: level >= 2)
            }
        }
    }
    
    // will be deprecated
    func speakingStateDidChange(_ seatIndex: UInt, speakingState isSpeaking: Bool) {
        
    }
    
    // room distory call back
    func roomDidClosed() {
        isRoomClosed = true
        if currentUserRole() != .creator {
            navigator(.voiceRoomAlert(title: "房主已关闭房间",
                                      actions: [.confirm("确定")],
                                      alertType: alertTypeVideoAlreadyClose,
                                      delegate: self))
        }
    }
    
    func messageDidReceive(_ message: RCMessage) {
        if message.content == nil { return }
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }
    
    func roomNotificationDidReceive(_ name: String, content: String) {
        guard let type = VoiceRoomNotification(rawValue: name) else {
            return
        }
        switch type {
        case .backgroundChanged:
            NotificationNameRoomBackgroundUpdated.post((voiceRoomInfo.roomId, content))
        case .rejectManagePick:
            if content == Environment.currentUserId {
                SVProgressHUD.showError(withStatus: "用户拒绝邀请")
            }
        case .agreeManagePick:
            if content == Environment.currentUserId {
                SVProgressHUD.showSuccess(withStatus: "用户连线成功")
            }
        case .forbiddenAdd:
            SceneRoomManager.shared.forbiddenWords.append(content)
        case .forbiddenDelete:
            SceneRoomManager.shared.forbiddenWords.removeAll(where: { $0 == content })
        case .inviteJoinGame:
            if content == Environment.currentUserId {
                self.receivedInviteGame()
            }
        case .switchGame:
            self.receivedSwitchGame(content: content)
        }
    }
    
    func pickSeatDidReceive(by userId: String) {
        handleReceivePickSeat(from: userId)
    }
    
    func kickSeatDidReceive(_ seatIndex: UInt) {
        SVProgressHUD.showSuccess(withStatus: "您已被抱下麦")
        if !(currentUserRole() == .creator) {
            self.roomState.connectState = .request
        } else {
            if (self.voiceRoomInfo.isOwner && (PlayerImpl.instance.currentPlayState == .mixingStatePlaying || PlayerImpl.instance.currentPlayState == .mixingStatePause)) {
                let _ = PlayerImpl.instance.stopMixing(with: nil)
            }
        }
        self.endGameAfterLeaveVoiceSeat()
    }
    
    func requestSeatDidAccept() {
       
    }
    
    func requestSeatDidReject() {
       
    }
    
    func requestSeatListDidChange() {
      
    }
    
    func invitationDidReceive(_ invitationId: String, from userId: String, content: String) {
        
    }
    
    func invitationDidAccept(_ invitationId: String) {
    }
    
    func invitationDidReject(_ invitationId: String) {
    }
    
    func invitationDidCancel(_ invitationId: String) {
        
    }
    
    func userDidKick(fromRoom targetId: String, byUserId userId: String) {
        roomInfoView.updateRoomUserNumber()
        if targetId == Environment.currentUserId {
            if managers.contains(where: { $0.userId == userId }) {
                RCSceneUserManager.shared.fetchUserInfo(userId: userId) { user in
                    SVProgressHUD.showInfo(withStatus: "您被管理员\(user.userName)踢出房间")
                }
            } else {
                SVProgressHUD.showInfo(withStatus: "您被踢出房间")
            }
            self.leaveRoom()
        }
    }
    
    func networkStatus(_ rtt: Int) {
        roomInfoView.updateNetworking(rtt: rtt)
    }    
}



extension GameRoomViewController: VoiceRoomAlertProtocol {
    func cancelDidClick(alertType: String) {
        
    }
    
    func confirmDidClick(alertType: String) {
        switch alertType {
        case alertTypeConfirmCloseRoom:
            closeRoom()
        case alertTypeVideoAlreadyClose:
            leaveRoom()
        default:
            ()
        }
    }
}
