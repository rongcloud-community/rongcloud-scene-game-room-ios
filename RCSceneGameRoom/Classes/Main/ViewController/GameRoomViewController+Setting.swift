//
//  GameRoomViewController+Setting.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/18.
//

import RCSceneRoom

extension GameRoomViewController {
    @_dynamicReplacement(for: setupModules)
    private func setupSettingModule() {
        setupModules()
    }
    
    @objc func handleSettingClick() {
        let notice = kvRoomInfo?.extra ?? "欢迎来到\(voiceRoomInfo.roomName)"
        var items: [Item] {
            return [
                .roomLock(voiceRoomInfo.isPrivate == 0),
                .roomName(voiceRoomInfo.roomName),
                .roomNotice(notice),
                .seatMute(!roomState.isMuteAll),
                .seatLock(!roomState.isLockAll),
                .speaker(enable: !roomState.isSilence),
                .forbidden(SceneRoomManager.shared.forbiddenWords),
                .music
            ]
        }
        let controller = RCSRSettingViewController(items: items, delegate: self)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true)
    }
}

extension GameRoomViewController: RCSceneRoomSettingProtocol {
    func eventWillTrigger(_ item: Item) -> Bool {
        switch item {
        case .forbidden:
            let roomId = voiceRoomInfo.roomId
            DispatchQueue.main.async {
                self.navigator(.forbiddenList(roomId: roomId))
            }
            return true
        default: return false
        }
    }
    
    func eventDidTrigger(_ item: Item, extra: String?) {
        switch item {
        case .roomLock(let lock):
            setRoomType(isPrivate: lock, password: extra)
        case .roomName(let name):
            roomUpdate(name: name)
        case .roomNotice(let notice):
            noticeDidModified(notice: notice)
        case .seatMute(let mute):
            muteAllSeatDidClick(isMute: mute)
        case .seatLock(let lock):
            lockAllSeatDidClick(isLock: lock)
        case .speaker(let enable):
            silenceSelfDidClick(isSilence: enable)
        case .music:
            presentMusicController()
        default: ()
        }
    }
}

extension GameRoomViewController {
    private func setRoomType(isPrivate: Bool, password: String?) {
        let title = isPrivate ? "设置房间密码" : "解锁"
        func onSuccess() {
            SVProgressHUD.showSuccess(withStatus: "已\(title)")
            voiceRoomInfo.isPrivate = isPrivate ? 1 : 0
        }
        func onError() {
            SVProgressHUD.showError(withStatus: title + "失败")
        }
        voiceRoomService.setRoomType(roomId: voiceRoomInfo.roomId,
                                     isPrivate: isPrivate,
                                     password: password) { result in
            switch result {
            case let .success(response):
                guard
                    let model = try? JSONDecoder().decode(RCSceneResponse.self, from: response.data),
                    model.validate()
                else { return onError() }
                onSuccess()
            case .failure: onError()
            }
        }
    }
    
    /// 全麦锁麦
    func muteAllSeatDidClick(isMute: Bool) {
        roomState.isMuteAll = isMute
        RCVoiceRoomEngine.sharedInstance().muteOtherSeats(isMute)
        SVProgressHUD.showSuccess(withStatus: isMute ? "全部麦位已静音" : "已解锁全麦")
    }
    
    /// 全麦锁座
    func lockAllSeatDidClick(isLock: Bool) {
        roomState.isLockAll = isLock
        RCVoiceRoomEngine.sharedInstance().lockOtherSeats(isLock)
        SVProgressHUD.showSuccess(withStatus: isLock ? "全部座位已锁定" : "已解锁全座")
    }
    /// 静音
    func silenceSelfDidClick(isSilence: Bool) {
        roomState.isSilence = isSilence
        PlayerImpl.instance.isSilence = isSilence
        RCVoiceRoomEngine.sharedInstance().muteAllRemoteStreams(isSilence)
        SVProgressHUD.showSuccess(withStatus: isSilence ? "扬声器已静音" : "已取消静音")
    }
    /// 音乐
    func musicDidClick() {
        presentMusicController()
    }
}

// mark:to be
//extension GameRoomViewController: RCSceneRoomPasswordProtocol {
//    func passwordDidEnter(password: String) {
//        setRoomType(isPrivate: true, password: password)
//    }
//#warning("这里可能是从礼物广播消息点击围观房间，输入完成房间密码后，走到这里")
//    func passwordDidVerify(_ room: RCSceneRoom) {
//        self.roomContainerSwitchRoom(room)
//    }
//}


extension GameRoomViewController {
    func roomUpdate(name: String) {
        if name.isEmpty {
            SVProgressHUD.showSuccess(withStatus: "房间名称不能为空")
            return
        }
        voiceRoomService.setRoomName(roomId: voiceRoomInfo.roomId, name: name) { result in
            switch result.map(RCSceneResponse.self) {
            case let .success(response):
                if response.validate() {
                    SVProgressHUD.showSuccess(withStatus: "更新房间名称成功")
                    if let roomInfo = self.kvRoomInfo {
                        roomInfo.roomName = name
                        RCVoiceRoomEngine.sharedInstance().setRoomInfo(roomInfo) {
                        } error: { code, msg in
                        }
                    }
                } else {
                    SVProgressHUD.showError(withStatus: response.msg ?? "更新房间名称失败")
                }
            case .failure:
                SVProgressHUD.showError(withStatus: "更新房间名称失败")
            }
        }
    }
}
