//
//  RCGameRoomSeat.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/5/31.
//

import UIKit
import RCSceneRoom

enum GameRoomUserState {
    case unJoin
    case unPrepare
    case prepared
    case selecting
    case painting
    case playing
}


public enum GameSeatUserRole {
    case owner
    case manager
    case onSeat
    case empty
}

struct RCGameSeatUser {
    var userId: String?
    var role: GameSeatUserRole
    var state: GameRoomUserState?
    var voiceSeatIndex: Int
    var isCaptain: Bool?
    var forbiddenMic: Bool?
}

