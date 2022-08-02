//
//  GameRoomViewController+Seats.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import SVProgressHUD
import UIKit
import SwiftUI
import AVFAudio
import RCSceneKit

extension GameRoomViewController {
    
    func isSitting(_ userId: String = Environment.currentUserId) -> Bool {
        return self.voiceRoomSeats.contains { $0.userId == userId }
    }
    
    public func fetchManagers() {
        voiceRoomService.roomManagers(roomId: voiceRoomInfo.roomId) { [weak self] result in
            switch result.map(managersWrapper.self) {
            case let .success(wrapper):
                guard let self = self else { return }
                self.managers = wrapper.data ?? []
                SceneRoomManager.shared.managers = self.managers.map(\.userId)
                self.sortSeats()
                self.managersChangeForHandleGameLogic()
            case let.failure(error):
                print(error.localizedDescription)
            }
        }
    }
    
    @_dynamicReplacement(for: managers)
    private var seats_managers: [RCSceneRoomUser] {
        get { managers }
        set {
            managers = newValue
            SceneRoomManager.shared.managers = managers.map(\.userId)
            messageView.tableView.reloadData()
        }
    }
    
    @_dynamicReplacement(for: userGiftInfo)
    var seats_userGiftInfo: [String: Int] {
        get {
            return userGiftInfo
        }
        set {
            userGiftInfo = newValue
        }
    }
    
    @_dynamicReplacement(for: handleReceivedMessage(_:))
    private func seats_handleReceivedMessage(_ message :RCMessage) {
        handleReceivedMessage(message)
        guard message.content.isKind(of: RCChatroomAdmin.self) else { return }
        // 更新管理员列表
        fetchManagers()
    }
    
}

extension GameRoomViewController {
    func enterSeatIfAvailable(_ isPicked: Bool = false) {
        if let index = self.voiceRoomSeats[0..<self.voiceRoomSeats.count].firstIndex(where: { $0.isEmpty }) {
            enterSeat(index: index)
        } else {
            self.unJoinGame()
            SVProgressHUD.showError(withStatus: "没有空座了，请稍后重试")
        }
    }
    
    func enterSeat(index: Int) {
        if roomState.isEnterSeatWaiting { return }
        roomState.isEnterSeatWaiting.toggle()
        RCVoiceRoomEngine.sharedInstance()
            .enterSeat(UInt(index)) { [weak self] in
                self?.roomState.isEnterSeatWaiting.toggle()
                DispatchQueue.main.async {
                    SVProgressHUD.showInfo(withStatus: "上麦成功")
                    self?.micStateButton.isHidden = false
                    self?.roomState.connectState = .connecting
                    guard let containerVC = self?.parent as? RCSPageContainerController else { return }
                    containerVC.setScrollable(false)
                }
            } error: { [weak self] code, msg in
                DispatchQueue.main.async {
                    SVProgressHUD.showInfo(withStatus: msg)
                    self?.roomState.isEnterSeatWaiting.toggle()
                }
            }
    }
    
    func leaveSeat(isKickout: Bool = false) {
        RCVoiceRoomEngine.sharedInstance().leaveSeat {
            [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                if !isKickout {
                    SVProgressHUD.showSuccess(withStatus: "下麦成功")
                } else {
                    SVProgressHUD.showSuccess(withStatus: "您已被抱下麦")
                }
                self.micStateButton.isHidden = true
                
                //mark: to be set delegate
                if !(self.currentUserRole() == .creator) {
                    self.roomState.connectState = .request
                    guard let containerVC = self.parent as? RCSPageContainerController else { return }
                    containerVC.setScrollable(true)
                }
                
                if self.voiceRoomInfo.isOwner {
                    let _ = PlayerImpl.instance.stopMixing(with: nil)
                }
                self.endGameAfterLeaveVoiceSeat()
            }
        } error: { code, msg in
            debugPrint("下麦失败\(code) \(msg)")
        }
    }
    
}

//MARK: - Seat CollectionView DataSource
extension GameRoomViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameSeatUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if gameSeatUsers.count == 0 || self.voiceRoomSeats.count == 0 {
            let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: SeatUserEmptyCell.self)
            return cell
        }
        let user = gameSeatUsers[indexPath.row]
        let voice = self.voiceRoomSeats[user.voiceSeatIndex]
        if user.role == .empty {
            let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: SeatUserEmptyCell.self)
            cell.update(user: user, voiceSeatInfo: voice)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: SeatUserViewCell.self)
            cell.update(user: user, voiceSeatInfo: voice)
            return cell
        }
    }
}


extension GameRoomViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let seatUser = gameSeatUsers[indexPath.row]
        let voiceSeat = self.voiceRoomSeats[seatUser.voiceSeatIndex]
        if currentUserRole() == .creator { // 当前登录用户 是房主
            if seatUser.role == .owner {  // 点自己
                clickMasterSeatUser(seatUser, [forbidSeatBtn, masterMicStateBtn, leaveSeatBtn], voiceSeat.isMuted)
            } else if seatUser.role == .empty { // 点空麦位
                if !isSitting()  {  // 如果自己还没有上麦，就上麦
                    enterSeat(index: seatUser.voiceSeatIndex)
                    // 加入游戏
                } else {
                    navigator(.ownerClickEmptySeat(voiceSeat, seatUser.voiceSeatIndex, self))
                }
            } else { // 点其他麦位
                var actions = [pickDownBtn, lockSeatBtn, muteBtn, kickOutBtn]
                if self.currentLoginUser() == self.captainUserId {
                    if self.currentGameState != .PLAYING {
                        if self.onPlaySeatUsers.contains(seatUser.userId!) { // 麦上用户加入游戏
                            actions.append(kickOutGameBtn)
                        } else {
                            actions.append(inviteGameBtn)
                        }
                    }
                }
                clickOnSeatUser(seatUser, true, actions)
            }
        } else if currentUserRole() == .manager { // 进入别人的房间, 且是管理员
            if seatUser.role == .empty { // 点空麦位
                // 如果自己还没有上麦，就上麦
                if isSitting() == false {
                    enterSeat(index: seatUser.voiceSeatIndex)
                    // 加入游戏
                }
            } else {
                if seatUser.userId == self.currentLoginUser() { // 点到自己
                    clickMasterSeatUser(seatUser, [masterMicStateBtn, leaveSeatBtn], voiceSeat.isMuted)
                } else if seatUser.role == .owner || seatUser.role == .manager {  // 点房主或者其他管理员
                    clickOnSeatUser(seatUser, false, nil)
                } else { // 点到其他人
                    var actions = [pickDownBtn, kickOutBtn]
                    if self.currentLoginUser() == self.captainUserId {
                        if self.currentGameState != .PLAYING {
                            if self.onPlaySeatUsers.contains(seatUser.userId!) { // 麦上用户加入游戏
                                actions.append(kickOutGameBtn)
                            } else {
                                actions.append(inviteGameBtn)
                            }
                        }
                    }
                    clickOnSeatUser(seatUser, false, actions)
                }
            }
        } else if currentUserRole() == .audience { // 普通观众进入别人的房间
            if seatUser.role == .empty { // 点空麦位
                // 如果自己还没有上麦，就上麦
                if !isSitting()  {
                    enterSeat(index: seatUser.voiceSeatIndex)
                }
            } else { // 麦上用户
                if seatUser.userId == self.currentLoginUser() { // 点到自己
                    clickMasterSeatUser(seatUser, [masterMicStateBtn, leaveSeatBtn], voiceSeat.isMuted)
                } else { // 点到其他人
                    var bottomButtons: [UIButton]? = nil
                    if self.currentLoginUser() == self.captainUserId {
                        if self.currentGameState != .PLAYING {
                            if self.onPlaySeatUsers.contains(seatUser.userId!) { // 麦上用户加入游戏
                                bottomButtons = [kickOutGameBtn]
                            } else {
                                bottomButtons = [inviteGameBtn]
                            }
                        }
                    }
                    clickOnSeatUser(seatUser, false, bottomButtons)
                }
            }
        }
    }
    
    
    func clickMasterSeatUser(_ gameSeatUser: RCGameSeatUser, _ actions: [UIButton]?, _ isForbidSeat: Bool) {
        self.forbidSeatBtn.isSelected = isForbidSeat
        let isDisable = RCVoiceRoomEngine.sharedInstance().isDisableAudioRecording()
        masterMicStateBtn.isSelected = !isDisable
        let vc = navigator(.masterSeatOperation(gameSeatUser, actions))
        self.currentMasterOperationVc = vc as? MasterSeatOperationViewController
    }
    
    func clickOnSeatUser(_ gameSeatUser: RCGameSeatUser, _ canSetManager: Bool, _ actions: [UIButton]?) {
        let vc = navigator(.onSeatUserOperation(bottomButtons: actions, gameSeatUser: gameSeatUser, delegate: self, canSetManager: canSetManager))
        self.currentUserOperationVc = vc as? OnSeatUserOperationController
    }
}

extension GameRoomViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 55, height: 55)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let width = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        return 5
    }
}


extension GameRoomViewController {
    func sortSeats() {
        
        self.gameSeatUsers.removeAll()
        self.collectionView.reloadData()
        
        RCVoiceRoomEngine.sharedInstance().getLatestSeatInfo { seatInfos in
            DispatchQueue.main.async {
                self.voiceRoomSeats = seatInfos
                if seatInfos.count == 0 { return }
                let roomOwnerId = self.voiceRoomInfo.userId
                
                let max = (self.kvRoomInfo?.seatCount ?? 9) - 1
                var rankIndexes = [Int](0...max)
                
                var playerInSeats = [RCGameSeatUser]()
                
                var captainUser: RCGameSeatUser?
                
                if let captain = self.captainUserId, self.onPlaySeatUsers.contains(captain) {
                    if let captainIndex = seatInfos.firstIndex { $0.userId == captain } {
                        
                        var role: GameSeatUserRole = .onSeat
                        if captain == roomOwnerId {
                            role = .owner
                        } else if self.managers.map(\.userId).contains(captain) {
                            role = .manager
                        }
                        
                        var state: GameRoomUserState = .unPrepare
                        
                        if self.currentGameState == .PLAYING {
                            state = .playing
                        } else if self.onReadyGameUsers.contains(captain) {
                            state = .prepared
                        }
                        
                        let user = RCGameSeatUser(userId: captain, role: role, state: state,
                                                  voiceSeatIndex: captainIndex, isCaptain: true)
                        
                        if self.currentUserRole() == .audience {
                            if captain == self.currentLoginUser() {
                                self.pickUsersButton.isHidden = false
                            } else {
                                self.pickUsersButton.isHidden = true
                            }
                        }
                        
                        captainUser = user
                        rankIndexes.removeAll { $0 == captainIndex }
                    }
                }
                
                if let captain = captainUser {
                    playerInSeats.append(captain)
                }
                
             
                for manager in self.managers.map(\.userId) { // 管理员
                    if let managerIndex = seatInfos.firstIndex { $0.userId == manager } {
                        if self.onPlaySeatUsers.contains(manager) {
                            if !playerInSeats.map(\.userId).contains(manager) {
                                var state: GameRoomUserState = .unPrepare
                                if self.currentGameState == .PLAYING {
                                    state = .playing
                                } else if self.onReadyGameUsers.contains(manager) {
                                    state = .prepared
                                }
                                
                                let user = RCGameSeatUser(userId: manager, role: .manager,
                                                          state: state, voiceSeatIndex: managerIndex, isCaptain: false)
                                playerInSeats.append(user)
                                rankIndexes.removeAll { $0 == managerIndex }
                            }
                        }
                    }
                }
                
                
                
                for player in self.onPlaySeatUsers { // 玩家
                    if let playerVoiceIndex = seatInfos.firstIndex { $0.userId == player } {
                        
                        var role: GameSeatUserRole = .onSeat
                        if player == roomOwnerId {
                            role = .owner
                        } else if self.managers.map(\.userId).contains(player) {
                            role = .manager
                        }
                        
                        
                        var state: GameRoomUserState = .unPrepare
                        if self.currentGameState == .PLAYING {
                            state = .playing
                        } else if self.onReadyGameUsers.contains(player) {
                            state = .prepared
                        }
                        
                        if !playerInSeats.map(\.userId).contains(player)  {
                            let user = RCGameSeatUser(userId: player, role: role, state: state,
                                                      voiceSeatIndex: playerVoiceIndex, isCaptain: false)
                            playerInSeats.append(user)
                            rankIndexes.removeAll { $0 == playerVoiceIndex }
                        }
                    }
                }
                
                if let captain = captainUser {
                    playerInSeats.remove(at: 0)
                    playerInSeats = playerInSeats.sorted {
                        if $0.role == .manager && $1.role != .manager {
                            return true
                        } else if  $0.role != .manager && $1.role == .manager {
                            return false
                        } else if $0.role == .manager && $1.role == .manager {
                            return $0.voiceSeatIndex < $1.voiceSeatIndex
                        } else {
                            return $0.voiceSeatIndex < $1.voiceSeatIndex
                        }
                    }
                      
                    playerInSeats = [captain] + playerInSeats
                } else {
                    playerInSeats = playerInSeats.sorted {
                        if $0.role == .manager && $1.role != .manager {
                            return true
                        } else if  $0.role != .manager && $1.role == .manager {
                            return false
                        } else if $0.role == .manager && $1.role == .manager {
                            return $0.voiceSeatIndex < $1.voiceSeatIndex
                        } else {
                            return $0.voiceSeatIndex < $1.voiceSeatIndex
                        }
                    }
                }
              
    
                var notInGameSeats = [RCGameSeatUser]()
                
                if let creatorIndex = seatInfos.firstIndex { $0.userId == roomOwnerId } { // 未加入游戏房主
                    if !playerInSeats.map(\.userId).contains(roomOwnerId) {
                        let creatorGameSeat = RCGameSeatUser(userId: self.voiceRoomInfo.userId,
                                                             role: .owner, state: .unJoin,
                                                             voiceSeatIndex: creatorIndex, isCaptain: false)
                        notInGameSeats.append(creatorGameSeat)
                        rankIndexes.removeAll { $0 == creatorIndex }
                    }
                }
                
                for manager in self.managers { // 未加入游戏管理员
                    if let managerIndex = seatInfos.firstIndex { $0.userId == manager.userId } {
                        if !playerInSeats.map(\.userId).contains(manager.userId) {
                            let managerGameSeat = RCGameSeatUser(userId: manager.userId, role: .manager,
                                                                 state: .unJoin, voiceSeatIndex: managerIndex, isCaptain: false)
                            notInGameSeats.append(managerGameSeat)
                            rankIndexes.removeAll { $0 == managerIndex }
                        }
                    }
                }
                
                let copyRankIndexes = [Int]() + rankIndexes
                for v in copyRankIndexes { // 麦上普通人
                    let voiceSeatInfo = seatInfos[v]
                    if voiceSeatInfo.status == .using {
                        let seatUser = RCGameSeatUser(userId: voiceSeatInfo.userId, role: .onSeat,
                                                      state: .unJoin, voiceSeatIndex: v, isCaptain: false)
                        notInGameSeats.append(seatUser)
                        rankIndexes.removeAll { $0 == v }
                    }
                }
                
                notInGameSeats = notInGameSeats.sorted { $0.voiceSeatIndex < $1.voiceSeatIndex }

                let emptyGameSeats = rankIndexes.map { RCGameSeatUser(role: .empty, state: .unJoin, voiceSeatIndex: $0) }
                

                self.gameSeatUsers = playerInSeats + notInGameSeats + emptyGameSeats
                
                self.collectionView.reloadData()
                
            }
            
        } error: { err, msg in
            
        }
    }
}
