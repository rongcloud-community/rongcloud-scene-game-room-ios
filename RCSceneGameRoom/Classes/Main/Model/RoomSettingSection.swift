//
//  RoomSettingView.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/6.
//

import UIKit

// mark:to be delete
enum ConnectMicState {
    case request
    case waiting
    case connecting
    
    var image: UIImage? {
        switch self {
        case .request:
            return RCSCAsset.Images.connectMicStateNone.image
        case .waiting:
            return RCSCAsset.Images.connectMicStateWaiting.image
        case .connecting:
            return RCSCAsset.Images.connectMicStateConnecting.image
        }
    }
}

struct RoomSettingState {
    var isMuteAll = false
    var isLockAll = false
    var isSilence = false
    var isEnterSeatWaiting = false
    var connectState: ConnectMicState = .request {
        didSet {
            debugPrint("connectState: \(connectState)")
            if connectState != oldValue {
                connectStateChanged?(connectState)
            }
        }
    }
    var connectStateChanged:((ConnectMicState) -> Void)?
}
