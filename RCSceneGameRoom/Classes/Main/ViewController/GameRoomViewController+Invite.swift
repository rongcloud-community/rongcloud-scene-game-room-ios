//
//  GameRoomViewController+Users.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/21.
//

import SVProgressHUD
import RCVoiceRoomLib

extension GameRoomViewController {
    
    @objc func handleMicButtonClick() {
        let navigation: RCNavigation = .requestOrInvite(roomId: voiceRoomInfo.roomId,
                                                        delegate: self,
                                                        showPage: 0)
        navigator(navigation)
    }


    func hasEmptySeat() -> Bool {
        return self.voiceRoomSeats[0..<self.voiceRoomSeats.count].contains { $0.isEmpty }
    }
}

// MARK: - Handle Seat Request Or Invite Delegate
extension GameRoomViewController: HandleRequestSeatProtocol {
    
    func loginUserRole() -> SceneRoomUserType {
        return self.currentUserRole()
    }
    
    func onSeatUserlist() -> [String] {
        return voiceRoomSeats.filter { $0.status == .using }.map(\.userId!)
    }
    
    func onGamePlayerList() -> [String] {
        return self.onPlaySeatUsers
        
    }
    
    func gameCaptainPlayer() -> String {
        return self.captainUserId ?? ""
    }
    
    func inviteVoiceForUser(userId: String) {
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
    
    func inviteGameForUser(userId: String) {
        if self.onPlaySeatUsers.contains(userId) {
            SVProgressHUD.showError(withStatus: "用户已进入游戏")
            return
        }
        SVProgressHUD.showSuccess(withStatus: "已邀请游戏")
        VoiceRoomNotification.inviteJoinGame.send(content: userId)
    }
    
    func acceptUserRequestSeat(userId: String) {
        
    }
    
}
