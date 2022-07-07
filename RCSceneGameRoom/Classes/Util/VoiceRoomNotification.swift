//
//  VoiceRoomStatus.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/25.
//

import Foundation

enum VoiceRoomNotification: String {
    case backgroundChanged = "VoiceRoomBackgroundChanged"
    case rejectManagePick = "VoiceRoomRejectManagePick"
    case agreeManagePick = "VoiceRoomAgreeManagePick"
    case forbiddenAdd = "EVENT_ADD_SHIELD"
    case forbiddenDelete = "EVENT_DELETE_SHIELD"
    case inviteJoinGame = "EVENT_INVITED_JOIN_GAME"
    case switchGame = "EVENT_SWITCH_GAME"
}

extension VoiceRoomNotification {
    func send(content: String) {
        RCVoiceRoomEngine.sharedInstance().notifyVoiceRoom(self.rawValue, content: content)
    }
}
