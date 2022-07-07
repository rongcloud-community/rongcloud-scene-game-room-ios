//
//  GameRoomViewController+Operations.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/30.
//

import UIKit
import SVProgressHUD
import RCSceneRoom
import SwiftUI

enum OnSeatUserAction {
    case pickDown
    case lockSeat
    case mute
    case kickOut
    case inviteVoice
    case inviteGame
    case kickOutGame
    case changeEnterSeat
    
    var button: UIButton {
        switch self {
        case .pickDown:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("抱下麦", for: .normal)
            instance.setImage(RCSCAsset.Images.pickUserDownSeatIcon.image, for: .normal)
            return instance
            
        case .lockSeat:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("关闭座位", for: .normal)
            instance.setTitle("打开座位", for: .selected)
            instance.setImage(RCSCAsset.Images.voiceroomSettingLockallseat.image, for: .normal)
            return instance
            
        case .mute:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("座位禁麦", for: .normal)
            instance.setImage(RCSCAsset.Images.voiceroomSettingMuteall.image, for: .normal)
            instance.setTitle("座位开麦", for: .selected)
            instance.setImage(RCSCAsset.Images.voiceroomSettingUnmuteall.image, for: .selected)
            return instance
            
        case .kickOut:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("踢出房间", for: .normal)
            instance.setImage(RCSCAsset.Images.kickOutRoomIcon.image, for: .normal)
            return instance
            
        case .inviteVoice:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("邀请上麦", for: .normal)
            instance.setImage(RCSCGameRoomAsset.inviteSeatAction.image, for: .normal)
            return instance
            
        case .inviteGame:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("邀请游戏", for: .normal)
            instance.setImage(RCSCGameRoomAsset.inviteUserGame.image, for: .normal)
            return instance
            
         case .kickOutGame:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("踢出游戏", for: .normal)
            instance.setImage(RCSCGameRoomAsset.kickUserLeaveGame.image, for: .normal)
            return instance
            
        case .changeEnterSeat:
            let instance = UIButton()
            instance.backgroundColor = .clear
            instance.titleLabel?.font = .systemFont(ofSize: 12)
            instance.setTitle("换我上麦", for: .normal)
            instance.setImage(RCSCGameRoomAsset.changeMeEnterSeat.image, for: .normal)
            return instance
        }
    }
}



extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupOperationModule() {
        setupModules()
        
        // OnSeatUserOperationController bottomBarButtons
        pickDownBtn.addTarget(self, action: #selector(handlePickDownUser), for: .touchUpInside)
        lockSeatBtn.addTarget(self, action: #selector(handleLockSeat), for: .touchUpInside)
        muteBtn.addTarget(self, action: #selector(handleMuteSeat), for: .touchUpInside)
        kickOutBtn.addTarget(self, action: #selector(handleKickOut), for: .touchUpInside)
        inviteGameBtn.addTarget(self, action: #selector(handleInviteGame), for: .touchUpInside)
        kickOutGameBtn.addTarget(self, action: #selector(handleKickOutGame), for: .touchUpInside)

    
        // MasterSeatOperationViewController sheetActions
        forbidSeatBtn.addTarget(self, action: #selector(handleForbiddenSeat), for: .touchUpInside)
        masterMicStateBtn.addTarget(self, action: #selector(disableAudioRecording), for: .touchUpInside)
        leaveSeatBtn.addTarget(self, action: #selector(handleLeaveSeat), for: .touchUpInside)
    }
    
    @objc private func handlePickDownUser() {
        guard let userId = currentUserOperationVc?.currentSeatUser.userId else {
            return
        }
        
        currentUserOperationVc?.dismiss(animated: true) {
            RCVoiceRoomEngine.sharedInstance().kickUser(fromSeat: userId) {
                SVProgressHUD.showSuccess(withStatus: "发送下麦通知成功")
            } error: { code, msg in
                SVProgressHUD.showError(withStatus: "发送下麦通知失败")
            }
        }
    }
    
    @objc private func handleLockSeat() {
        guard let voiceSeatIndex = currentUserOperationVc?.currentSeatUser.voiceSeatIndex else {
            return
        }
        currentUserOperationVc?.dismiss(animated: true) {
            let voiceSeatInfo = self.voiceRoomSeats[voiceSeatIndex]
            let toSet = !(voiceSeatInfo.status == .locking)
            
            RCVoiceRoomEngine.sharedInstance().lockSeat(UInt(voiceSeatIndex), lock: toSet) {
                self.lockSeatBtn.isSelected = toSet
            } error: { errCode, msg in
                
            }
        }
    }
    
    @objc private func handleMuteSeat() {
        guard let voiceSeatIndex = currentUserOperationVc?.currentSeatUser.voiceSeatIndex else {
            return
        }
        currentUserOperationVc?.dismiss(animated: true) {
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
    
    @objc private func handleKickOut() {
        guard let userId = currentUserOperationVc?.currentSeatUser.userId else {
            return
        }
        currentUserOperationVc?.dismiss(animated: true) {
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
    }
    
    @objc private func handleInviteGame() {
        guard let userId = currentUserOperationVc?.currentSeatUser.userId else {
            return
        }
        currentUserOperationVc?.dismiss(animated: true) {
            VoiceRoomNotification.inviteJoinGame.send(content: userId)
        }
    }

    
    @objc private func handleKickOutGame () {
        guard let userId = currentUserOperationVc?.currentSeatUser.userId else {
            return
        }
        currentUserOperationVc?.dismiss(animated: true) {
            RCGameEngine.shared().kickPlayer(userId) { _,_,_ in }
        }
    }
}


// MARK: - Owenr Seat Pop View Delegate
extension GameRoomViewController {
    @objc private func handleForbiddenSeat() {
        guard let vc = self.currentMasterOperationVc else {
            return
        }
        vc.dismiss(animated: true) {
            let voiceSeatIndex = vc.gameSeatUser.voiceSeatIndex
            let voiceSeatInfo = self.voiceRoomSeats[voiceSeatIndex]
            let toMute = !(voiceSeatInfo.isMuted)
      
            RCVoiceRoomEngine.sharedInstance().muteSeat(UInt(voiceSeatIndex), mute: toMute) {
                self.forbidSeatBtn.isSelected = !toMute
                 // 这里会触发seatInfoDidUpdate - fetchManagers() - sortSeats()
            } error: { code, msg in
                
            }
        }
    }
    
    @objc private func disableAudioRecording() {
        guard let vc = self.currentMasterOperationVc else {
            return
        }
        vc.dismiss(animated: true) {
            let toMute = !RCVoiceRoomEngine.sharedInstance().isDisableAudioRecording()
            RCVoiceRoomEngine.sharedInstance().disableAudioRecording(toMute)
            if toMute {
                SVProgressHUD.showSuccess(withStatus: "麦克风已关闭")
            } else {
                SVProgressHUD.showSuccess(withStatus: "麦克风已打开")
            }
            self.micStateButton.isSelected = toMute
        }
    }
    
    @objc private func handleLeaveSeat() {
        guard let vc = self.currentMasterOperationVc else {
            return
        }
        vc.dismiss(animated: true) {
            if SceneRoomManager.shared.currentPlayingStatus == RCRTCAudioMixingState.mixingStatePlaying {
                self.showMusicAlert()
            } else {
                self.leaveSeat()
            }
        }
    }
    
    private func showMusicAlert() {
        let vc = UIAlertController(title: "播放音乐中下麦会导致音乐终端，是否确定下麦？", message: nil, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "确定", style: .default, handler: { _ in
            self.leaveSeat()
            self.dismiss(animated: true, completion: nil)
        }))
        vc.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { _ in
            
        }))
        let topVC = UIApplication.shared.topmostController()
        topVC?.present(vc, animated: true, completion: nil)
    }
    
}


// MARK: - Owner Click Empty User Seat Pop View Delegate
extension GameRoomViewController: VoiceRoomEmptySeatOperationProtocol {
    func emptySeat(_ index: Int, isLock: Bool) {
        let title = isLock ? "关闭" : "打开"
        RCVoiceRoomEngine.sharedInstance().lockSeat(UInt(index), lock: isLock) {
            SVProgressHUD.showSuccess(withStatus: "\(title)\(index)号麦位成功")
        } error: { code, msg in
            SVProgressHUD.showError(withStatus: "\(title)\(index)号麦位失败")
        }
    }
    
    func emptySeat(_ index: Int, isMute: Bool) {
        RCVoiceRoomEngine.sharedInstance().muteSeat(UInt(index), mute: isMute) {
            if isMute {
                SVProgressHUD.showSuccess(withStatus: "此麦位已禁麦")
            } else {
                SVProgressHUD.showSuccess(withStatus: "此麦位取消禁麦")
            }
        } error: { code, msg in
            
        }
    }
    
    func emptySeatInvitationDidClicked() {
        let navigation = RCNavigation.requestOrInvite(roomId: voiceRoomInfo.roomId,
                                                      delegate: self,
                                                      showPage: 1)
        navigator(navigation)
    }
}

extension GameRoomViewController: OnSeatUserOperationProtocol {
    
    func viewDidLoad(controller: OnSeatUserOperationController) {
        let voiceSeatIndex = controller.currentSeatUser.voiceSeatIndex
        let voiceSeatInfo = self.voiceRoomSeats[voiceSeatIndex]
        
        self.lockSeatBtn.isSelected = voiceSeatInfo.status == .locking
        self.muteBtn.isSelected = voiceSeatInfo.isMuted
    }
    
    func didClickedSendGift(controller: OnSeatUserOperationController) {
        let userId = controller.currentSeatUser.userId!
        let seatUsers = self.voiceRoomSeats.map { $0.userId ?? "" }
        let dependency = RCSceneGiftDependency(room: voiceRoomInfo,
                                               seats: seatUsers,
                                               userIds: [userId])
        navigator(.giftToUser(dependency: dependency, delegate: self))
    }
    
    
    func didClickedPrivateChat(controller: OnSeatUserOperationController) {
        let userId = controller.currentSeatUser.userId!
        let vc = ChatViewController(.ConversationType_PRIVATE, userId: userId)
        vc.delegate = self
        vc.canCallComing = false
        navigationController?.navigationBar.isHidden = false
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func didClickedFollow(controller: OnSeatUserOperationController) {
        let userId = controller.currentSeatUser.userId!
        userProvider.request(.follow(userId: userId)) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(res):
                if res.validate() {
                    controller.isCurrentUserFollowed = true
                    controller.updateFollowButton()
                    RCSceneUserManager.shared.refreshUserInfo(userId: userId) { followUser in
                        RCSceneUserManager.shared.fetchUserInfo(userId: Environment.currentUserId) { [weak self] user in
                            let message = RCChatroomFollow()
                            message.userInfo = user.rcUser
                            message.targetUserInfo = followUser.rcUser
                            self?.chatroomSendMessage(message)
                        }
                    }
                } else {
                    SVProgressHUD.showError(withStatus: "关注请求失败")
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }

    func didClickedSetManager(controller: OnSeatUserOperationController) {
        let userId = controller.currentSeatUser.userId!
        let roomId = voiceRoomInfo.roomId
        let toSet = !controller.isCurrentUserManager
        roomProvider.request(.setRoomManager(roomId: roomId, userId: userId, isManager: toSet)) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(res):
                if res.validate() {
                    controller.isCurrentUserManager = toSet
                    controller.updateManageButton()
                    if toSet {
                        SVProgressHUD.showSuccess(withStatus: "已设为管理员")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "已撤回管理员")
                    }
                    RCSceneUserManager.shared.fetchUserInfo(userId: userId) { user in
                        let event = RCChatroomAdmin()
                        event.userId = user.userId
                        event.userName = user.userName
                        event.isAdmin = toSet
                        self.chatroomSendMessage(event)
                    }                    
                    self.fetchManagers()
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}



extension GameRoomViewController: ChatViewControllerProtocol {
    func chatViewControllerBack() {
        navigationController?.navigationBar.isHidden = true
    }
}
