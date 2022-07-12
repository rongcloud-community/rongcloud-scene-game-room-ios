
import UIKit
import RCSceneRoom
import Kingfisher

extension GameRoomViewController {
    
    @_dynamicReplacement(for: setupModules)
    private func setupAudioModule() {
        setupModules()
        switchGameView.addTarget(self, action: #selector(gameSwitchAction))
        
        RCGameEngine.shared().gameStateDelegate = self
        RCGameEngine.shared().playerStateDelegate = self
    }
    
    public func prepareGameEngine(gameInfo: RCSceneGameResp?) {
        // check / get game engine app code
        if let codeSaved = UserDefaults.standard.gameEngineAppCode() {
            loadGameEngine(appCode: codeSaved, gameId: gameInfo?.gameId)
        } else {
            let currentLoginId = self.currentLoginUser()
            let api = RCGameRoomService.gameEngineLogin(userId: currentLoginId)
            gameRoomProvider.request(api) { result in
                switch result.map(RCSceneWrapper<RCGameLoginResp>.self) {
                case let .success(wrapper):
                    if let gameLoginResp = wrapper.data {
                        UserDefaults.standard.set(gameEngineAppCode: gameLoginResp.code)
                        self.loadGameEngine(appCode: gameLoginResp.code, gameId: gameInfo?.gameId)
                    }
                case let .failure(error): break
                }
            }
        }
    }
    
    private func loadGameEngine(appCode: String, gameId: String?) {
        guard let gameId = gameId else { return }
        let opt = RCGameOption.default()!
        let scale = UIScreen.main.nativeScale
        let safeInset = UIWindow.compatibleKeyWindow?.safeAreaInsets ?? UIEdgeInsets();
        let top = (safeInset.top + 120) * scale
        let bottom = (safeInset.bottom + 150) * scale
        opt.gameSafeRect = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        
        opt.gameUI.levelHide(true)
        opt.gameUI.lobbyPlayersCustom(false, hide: false)
        opt.gameUI.lobbyPlayerCaptainIconHide(false)
        opt.gameUI.pingHide(true)
        
        
        let gameRoomInfo = RCGameRoomInfo()
        gameRoomInfo.gameId = gameId
        gameRoomInfo.appCode = appCode
        gameRoomInfo.roomId = voiceRoomInfo.roomId
        gameRoomInfo.userId = self.currentLoginUser()
        
        RCGameEngine.shared().getGameList { _,_ in
            RCGameEngine.shared().loadGame(with: self.view, roomInfo: gameRoomInfo, gameOption: opt)
        }
        
    }
    
    @objc private func gameSwitchAction(btn: UIButton) {
        navigator(.switchGame(games: [], delegate: self))
    }
    
    func receivedInviteGame() {
        if let prevAlert = self.inviteGameAlert {
            return
        } else {
            let alertVC = UIAlertController(title: "邀请游戏", message: "队长邀请你加入游戏，是否同意？", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "同意", style: .default, handler: { _ in
                self.inviteGameAlert = nil
                RCGameEngine.shared().joinGame { code, resMsg, dataJson in }
            }))
            alertVC.addAction(UIAlertAction(title: "拒绝", style: .cancel, handler: { _ in
                self.inviteGameAlert = nil
            }))
            
            self.topmostController().present(alertVC, animated: true)
            self.inviteGameAlert = alertVC
        }
    }
    
    func unJoinGame() {
        RCGameEngine.shared().cancelReadyGame { code, resMsg, dataJson in  }
        RCGameEngine.shared().cancelJoinGame { code, resMsg, dataJson in  }
    }
    
    func endGameAfterLeaveVoiceSeat() {
        if self.currentGameState == .PLAYING {
            if self.currentLoginUser() == self.captainUserId { // 队长
                RCGameEngine.shared().endGame { code, resMsg, dataJson in }
            } else {
                RCGameEngine.shared().cancelPlayGame { code, resMsg, dataJson in }
            }
        } else {
            self.unJoinGame()
        }
    }
    
    // 收到切换房间的通知
    func receivedSwitchGame(content: String) {
        guard let data = content.data(using: .utf8) else { return }
        guard let game = try? JSONDecoder().decode(RCSceneGameResp.self, from: data) else {
            return
        }
        if currentUserRole() != .creator { // 非房主身份成员下麦
            self.leaveSeat()
        } else { // 房主退出游戏
            RCGameEngine.shared().cancelReadyGame { code, resMsg, dataJson in }
            RCGameEngine.shared().cancelJoinGame { code, resMsg, dataJson in }
        }
        self.switchGame(newGame: game, proactive: false)
    }
    
    
    func handleDrawGuessGame(keyword: String) {
        if voiceRoomInfo.gameResp?.gameName == "你画我猜" && self.currentGameState == .PLAYING {
            if let guessWord = self.onKeyword {
                if keyword == guessWord {
                    RCGameEngine.shared().hitKeyword(keyword) {  code, resMsg, dataJson in }
                }
            }
        }
    }
    
    func managersChangeForHandleGameLogic() {
        if self.currentUserRole() == .creator {
            pickUsersButton.isHidden = false
        } else if self.currentUserRole() == .manager { // 当前登录用户管理员
            pickUsersButton.isHidden = false
            switchGameView.isHidden = false
            switchGameView.update(game: voiceRoomInfo.gameResp?.gameName)
        } else {
            pickUsersButton.isHidden = true
            switchGameView.isHidden = true
        }
    }
    
    func drawAndGuessPushAudio(data: NSData) {
        RCGameEngine.shared().pushAudio(data as Data)
    }
    
}

extension GameRoomViewController: GameSwitchSelectDelegate {
    func didSelectForSwitch(game: RCSceneGameResp) { // 房主 / 管理员 点击切换完游戏
        if voiceRoomInfo.gameResp?.gameId == game.gameId { // 选中当前正在同样的游戏则不切换
            return
        }
        if currentUserRole() == .manager {  // 登陆用户为管理员 切换游戏，自己要下麦
            self.leaveSeat()
        }
        self.switchGame(newGame: game, proactive: true)
    }
    
    
    func switchGame(newGame: RCSceneGameResp, proactive: Bool) {
        guard let loadingPicUrl = URL(string: newGame.loadingPic) else {
            return
        }
        
        guard let roomInfo = self.kvRoomInfo else {
            return
        }
        
        if newGame.maxSeat > roomInfo.seatCount {
            let roomInfo = RCVoiceRoomInfo()
            roomInfo.roomName = self.voiceRoomInfo.roomName
            roomInfo.isFreeEnterSeat = true
            roomInfo.seatCount = newGame.maxSeat
            
            RCVoiceRoomEngine.sharedInstance().setRoomInfo(roomInfo) {
                self.kvRoomInfo = roomInfo
                self.handleSwitchGameLogic(newGame: newGame, proactive: proactive, loadingPicUrl: loadingPicUrl)
            } error: { _, _ in }
        } else {
            self.handleSwitchGameLogic(newGame: newGame, proactive: proactive, loadingPicUrl: loadingPicUrl)
        }
    }
    
    
    func handleSwitchGameLogic(newGame: RCSceneGameResp, proactive: Bool, loadingPicUrl: URL) {
        if self.currentGameState == .PLAYING && self.currentLoginUser() == self.captainUserId { // 队长结束游戏
            RCGameEngine.shared().endGame { code, resMsg, dataJson in }
        }
        
        self.voiceRoomInfo.gameResp = newGame
        
        // 当前用户退出游戏
        self.currentGameState == .IDLE
        
        topContainerView.isHidden = true
        bottomContainerView.isHidden = true
        
        // 清除数据
        gameSeatUsers.removeAll()
        onPlaySeatUsers.removeAll()
        onReadyGameUsers.removeAll()
        self.captainUserId = nil
        self.onKeyword = nil
        
        
        // 通知别人
        if proactive {
            guard let encodedData = try? JSONEncoder().encode(newGame) else {
                return
            }
            guard let jsonString = String(data: encodedData, encoding: .utf8) else {
                return
            }
            VoiceRoomNotification.switchGame.send(content: jsonString)
        }
        self.gameSwitching = true
        
        SVProgressHUD.show()
        KingfisherManager.shared.downloader.downloadImage(with: loadingPicUrl, options: [.memoryCacheExpiration(.expired)]) { result in
            switch result {
            case let .success(imageLoadingResult):
                SVProgressHUD.dismiss()
                self.backgroundImageView.isHidden = false
                self.backgroundImageView.image = imageLoadingResult.image
                
                RCGameEngine.shared().destroy()
                RCGameEngine.shared().switchGame(newGame.gameId) { code, resMsg, dataJson in
                    self.reportSwitchGame(gameId: newGame.gameId)
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.errorDescription)
            }
        }
    }
    
    
    func reportSwitchGame(gameId: String) {
        gameRoomProvider.request(.switchGame(gameId: gameId, gameState: 1, roomId: voiceRoomInfo.roomId)) { result in
            SVProgressHUD.showSuccess(withStatus: "游戏已经切换")
        }
    }
    
}



extension GameRoomViewController: RCGameStateDelegate {
    func onGameASRChanged(_ isOpen: Bool) {
        
    }
    
    func onGameLoadingProgress(_ loadingStage: RCGameLoadingStage, errorCode: Int, progress: Int) {
        
    }
    
    func onGameLoaded() {
        RCRTCEngine.sharedInstance().defaultAudioStream.bitrateValue = 16000
        RCRTCEngine.sharedInstance().defaultAudioStream.audioCodecType = .PCMU
        RCRTCEngine.sharedInstance().defaultAudioStream.setAudioQuality(.musicHigh, scenario: .default)
        
        topContainerView.isHidden = false
        bottomContainerView.isHidden = false
        backgroundImageView.isHidden = true
        
        if (self.isFastIn == true) || (isCreate && currentUserRole() == .creator) { // 当前用户创建的房间
            if self.gameSwitching {
                self.gameSwitching = false
                self.collectionView.reloadData()
            } else {
                RCGameEngine.shared().joinGame { code, resMsg, dataJson in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        RCGameEngine.shared().readyGame { code, msg, dataJson in }
                    }
                }
            }
        }
        
        if currentUserRole() != .audience {
            switchGameView.isHidden = false
        }
        switchGameView.update(game: voiceRoomInfo.gameResp?.gameName)
    }
    
    func onGameDestroyed() {
        
    }
    
    func onReceivePublicMessage(_ attributedMessage: NSAttributedString, rawMessage: String) {
        let gameMessage = RCGameMessage(attributedMessage: attributedMessage)
        addMessageToView(gameMessage)
    }
    
    func onKeyword(toHit keyword: String) {
        self.onKeyword = keyword
    }
    
    
    
    func onGameStateChanged(_ gameState: RCGameState) {
        self.currentGameState = gameState
        if let gameId = self.voiceRoomInfo.gameResp?.gameId {
            let state = (gameState == .PLAYING ? 2 : 1)
            gameRoomProvider.request(.gameStatus(gameId: gameId, gameState: state, roomId: self.voiceRoomInfo.roomId)) { result in }
        }
    }
    
    
    func onMicrophoneChanged(_ isOpen: Bool) {
        //isPushAudioData = isOpen
    }
    
    
    func onExpireCode() {
        let currentLoginId = self.currentLoginUser()
        let api = RCGameRoomService.gameEngineLogin(userId: currentLoginId)
        gameRoomProvider.request(api) { result in
            switch result.map(RCSceneWrapper<RCGameLoginResp>.self) {
            case let .success(wrapper):
                if let gameLoginResp = wrapper.data {
                    UserDefaults.standard.set(gameEngineAppCode: gameLoginResp.code)
                    RCGameEngine.shared().updateCode(gameLoginResp.code)
                }
            case let .failure(error): break
            }
        }
    }
    
    func onGameSettle(_ gameSettle: RCGameSettle) {
        isPushAudioData = false
        if self.isRoomClosed == true {
            if currentUserRole() == .creator {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                    self?.closeRoom()
                }
            }
        }
    }
    
    func onGameLog(_ dataJson: String) {
        
    }
    
}


extension GameRoomViewController: RCGamePlayerStateDelegate {
    func onPlayerTurnStatus(_ userId: String, isTurn: Bool) {
        
    }
    
    func onPlayerDieStatus(_ userId: String, isDeath: Bool) {
        
    }
    
    func onPlayer(in userId: String, isIn: Bool, teamId: Int) {
        let loginUser = self.currentLoginUser()
        let roomOwnerId = self.voiceRoomInfo.userId
        
        if isIn {
            if !self.onPlaySeatUsers.contains(userId) {
                self.onPlaySeatUsers.append(userId)
            }
            
            if userId == roomOwnerId { // 房主进游戏
                if userId != self.captainUserId {
                    //if loginUser == roomOwnerId {
                    self.resetCaptain(userId)
                    // }
                }
            } else if self.managers.map(\.userId).contains(userId) { // 管理员
                if self.captainUserId == nil {
                    // if loginUser == userId {
                    self.resetCaptain(userId)
                    //}
                }
            }
            
            if userId == loginUser {  // 当前登陆用户不在麦上
                if !isSitting(userId) {
                    enterSeatIfAvailable()
                }
            }
            
        } else { // 有用户退出游戏
            self.onPlaySeatUsers.removeAll { $0 == userId }
            
            if userId == self.captainUserId {
                self.captainUserId = nil
            }
            
            if self.onReadyGameUsers.contains(userId) {
                self.onReadyGameUsers.removeAll { $0 == userId }
            }
            
            if userId == loginUser && self.loginUserRole() == .audience {
                pickUsersButton.isHidden = true
            }
            
            if self.captainUserId == nil {
                for player in self.onPlaySeatUsers {
                    if player == roomOwnerId { // 房主
                        self.resetCaptain(player)
                    } else if self.managers.map(\.userId).contains(player) { // 管理员
                        self.resetCaptain(player)
                    }
                }
            }
        }
        
        self.sortSeats()
    }
    
    
    func resetCaptain(_ userId: String) {
        self.captainUserId = userId
        RCGameEngine.shared().setCaptain(userId) { code, msg, dataJson in }
    }
    
    func onPlayerCaptain(_ userId: String, isCaptain: Bool) {
        if isCaptain {
            self.captainUserId = userId
        }
        self.sortSeats()
    }
    
    
    func onPlayerReady(_ userId: String, isReady: Bool) {
        if isReady {
            self.onReadyGameUsers.append(userId)
        } else {
            self.onReadyGameUsers.removeAll { $0 == userId }
        }
        if let i = self.gameSeatUsers.firstIndex { $0.userId == userId }  {
            gameSeatUsers[i].state = isReady ? .prepared : .unPrepare
            self.collectionView.reloadData()
        }
    }
    
    func onPlayerPlaying(_ userId: String, isPlaying: Bool) {
        if let i = self.gameSeatUsers.firstIndex { $0.userId == userId }  {
            gameSeatUsers[i].state = isPlaying ? .playing : .unPrepare
            self.collectionView.reloadData()
        }
    }
    
    func onPlayerChangeSeat(_ userId: String, from: Int, to: Int) {
        
    }
    
}


extension GameRoomViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print("scrollViewWillBeginDragging")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print("scrollViewDidEndDecelerating")
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //print("scrollViewDidEndDragging")
    }
    
}
