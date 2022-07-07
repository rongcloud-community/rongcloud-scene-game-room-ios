//
//  GameRoomViewController+More.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/22.
//

import SVProgressHUD
import RCSceneRoom

extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
        
        moreButton.addTarget(self, action: #selector(handleMoreButton), for: .touchUpInside)
        roomNoticeButton.addTarget(self, action: #selector(openRoomNotice), for: .touchUpInside)
    }
    
    @objc private func handleMoreButton() {
        navigator(.leaveAlert(isOwner: currentUserRole() == .creator, delegate: self))
    }
    
    @objc private func openRoomNotice() {
        let notice = kvRoomInfo?.extra ?? "欢迎来到\(voiceRoomInfo.roomName)"
        navigator(.notice(notice: notice, delegate: self))
    }
}

extension GameRoomViewController: VoiceRoomNoticeDelegate {
    func noticeDidModified(notice: String) {
        LiveNoticeChecker.check(notice) { pass, msg in
            guard let kvRoom = self.kvRoomInfo, pass else {
                return SVProgressHUD.showError(withStatus: msg)
            }
            kvRoom.extra = notice
            RCVoiceRoomEngine.sharedInstance().setRoomInfo(kvRoom) {
                SVProgressHUD.showSuccess(withStatus: "修改公告成功")
            } error: { code, msg in
                SVProgressHUD.showError(withStatus: "修改公告失败 \(msg)")
            }
            let textMessage = RCTextMessage()
            textMessage.content = "房间公告已更新"
            RCVoiceRoomEngine.sharedInstance().sendMessage(textMessage) {
                [weak self] in
                DispatchQueue.main.async {
                    self?.addMessageToView(textMessage)
                }
            } error: { code, msg in
                
            }
        }
    }
}



// MARK: - Leave View Click Delegate
extension GameRoomViewController: RCSceneLeaveViewProtocol {
    func scaleRoomDidClick() {
        
    }
    
    func quitRoomDidClick() {
        if self.currentGameState == .PLAYING {
            if self.currentLoginUser() == self.captainUserId { // 队长
                if currentUserRole() == .creator {
                    RCGameEngine.shared().endGame { code, resMsg, dataJson in
                        for player in self.onPlaySeatUsers {
                            if self.managers.map(\.userId).contains(player) { // 管理员
                                self.resetCaptain(player)
                                break
                            }
                        }
                        if self.captainUserId == nil { // 房主，管理员都不在， 游戏自动分配
                            
                        }
                    }
                }
            } else {
                RCGameEngine.shared().cancelPlayGame { code, resMsg, dataJson in }
            }
        }
        leaveRoom()
    }
    
    func closeRoomDidClick() { // 房主关闭房间
        self.isRoomClosed = true
        if self.currentGameState == .PLAYING { //  房主在游戏中
            RCGameEngine.shared().endGame { code, resMsg, dataJson in }
        } else {
            closeRoom()
        }
    }
}

