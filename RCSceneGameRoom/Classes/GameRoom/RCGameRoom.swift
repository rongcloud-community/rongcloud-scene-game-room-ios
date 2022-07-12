import RCSceneRoom


public var RCSceneVoiceRoomEnableSwitchableBackgroundImage = false

public func RCGameEngineInit(isDebug: Bool)  {
    let gconfig = RCGameConfig()
    gconfig.isDebug = isDebug
    RCGameEngine.shared().initWithAppId("1496435759618818049", appKey: "YS7NZ6rUAnbi0DruJJiUCmcH1AkCrQk6", config: gconfig) { code, resMsg, dataJson in
        
    }
}


public func RCGameRoomController(room: RCSceneRoom, creation: Bool = false, preloadBgImage: UIImage? = nil, isFastIn: Bool = false, switchNewGame: RCSceneGameResp? = nil) -> RCRoomCycleProtocol {
    RCSceneIMMessageRegistration()
    let gameVc = GameRoomViewController(roomInfo: room, isCreate: creation, preloadBgImage: preloadBgImage, switchNewGame: switchNewGame)
    gameVc.isFastIn = isFastIn
    return gameVc

}

extension GameRoomViewController: RCRoomCycleProtocol {
    func setRoomContainerAction(action: RCRoomContainerAction) {
        self.roomContainerAction = action
    }
    
    func setRoomFloatingAction(action: RCSceneRoomFloatingProtocol) {
        self.floatingManager = action
    }
    
    func joinRoom(_ completion: @escaping (Result<Void, RCSceneError>) -> Void) {
        SceneRoomManager.shared.voice_join(voiceRoomInfo.roomId, complation: completion)
    }
    
    func leaveRoom(_ completion: @escaping (Result<Void, RCSceneError>) -> Void) {
        SceneRoomManager.shared.voice_leave(completion)
    }
    
    func descendantViews() -> [UIView] {
        return [messageView.tableView]
    }
}

fileprivate var isIMMessageRegistration = false
fileprivate func RCSceneIMMessageRegistration() {
    if isIMMessageRegistration { return }
    isIMMessageRegistration = true
    RCChatroomMessageCenter.registerMessageTypes()
    RCIM.shared().registerMessageType(RCGiftBroadcastMessage.self)
    RCIM.shared().registerMessageType(RCPKStatusMessage.self)
}
