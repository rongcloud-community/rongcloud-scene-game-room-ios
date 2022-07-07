//
//  RCRouter.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/20.
//

import UIKit
import RCSceneRoom

enum RCNavigation: Navigation {
    case voiceRoom(roomInfo: RCSceneRoom, needCreate: Bool)
    case requestOrInvite(roomId: String, delegate: HandleRequestSeatProtocol, showPage: Int)
    case masterSeatOperation(RCGameSeatUser, [UIButton]?)
    case ownerClickEmptySeat(RCVoiceSeatInfo, Int, VoiceRoomEmptySeatOperationProtocol)
    case inputText(name: String, delegate: VoiceRoomInputTextProtocol)
    case inputPassword(completion: RCSRPasswordCompletion)
    case userlist(room: RCSceneRoom, delegate: UserListViewControllerProtocol)
    case giftToUser(dependency: RCSceneGiftDependency, delegate: RCSceneGiftViewControllerDelegate)
    case gift(dependency: RCGameSceneGiftDependency, delegate: RCGameSceneGiftViewControllerDelegate)
    case voiceRoomAlert(title: String, actions: [VoiceRoomAlertAction], alertType: String, delegate: VoiceRoomAlertProtocol?)
    case leaveAlert(isOwner: Bool, delegate: RCSceneLeaveViewProtocol)
    case notice(modify: Bool = false, notice: String, delegate: VoiceRoomNoticeDelegate)
    case forbiddenList(roomId: String)
    case switchGame(games: [RCSceneGameResp], delegate: GameSwitchSelectDelegate?)
    case onSeatUserOperation(bottomButtons: [UIButton]?, gameSeatUser: RCGameSeatUser, delegate: OnSeatUserOperationProtocol?, canSetManager: Bool)
}

struct RCAppNavigation: AppNavigation {
    func navigate(_ navigation: Navigation, from: UIViewController, to: UIViewController) {
        if let router = navigation as? RCNavigation {
            switch router {
            case
                    .requestOrInvite,
                    .masterSeatOperation,
                    .ownerClickEmptySeat,
                    .inputText,
                    .inputPassword,
         
                    .gift,
                    .giftToUser,
                    .voiceRoomAlert,
                    .leaveAlert,
                    .notice,
                    .forbiddenList,
                    .switchGame,
                    .onSeatUserOperation:
                from.present(to, animated: true, completion: nil)
              case .userlist:
                from.present(to, animated: true, completion: nil)
            default:
                from.navigationController?.pushViewController(to, animated: true)
            }
        }
    }
    
    func viewControllerForNavigation(navigation: Navigation) -> UIViewController {
        guard let router = navigation as? RCNavigation else {
            return UIViewController()
        }
        switch router {
        case let .voiceRoom(roomInfo, needCreate):
            return GameRoomViewController(roomInfo: roomInfo, isCreate: needCreate)
        case let .requestOrInvite(roomId, delegate, page):
            return RequestOrInviteViewController(roomId: roomId, delegate: delegate, showPage: page)
        case let .masterSeatOperation(user, actions):
            let vc = MasterSeatOperationViewController(gameSeatUser: user, actions: actions)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .ownerClickEmptySeat(info, index, delegate):
            let vc = VoiceRoomEmptySeatOperationViewController(seatInfo: info, seatIndex: index, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .inputText(name, delegate):
            let vc = VoiceRoomTextInputViewController(name: name, delegate: delegate)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .inputPassword(completion):
            let vc = RCSRPasswordViewController()
            vc.completion = completion
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .userlist(room, delegate):
            let vc = UserListViewController(room: room, delegate: delegate)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalTransitionStyle = .crossDissolve
            nav.modalPresentationStyle = .overFullScreen
            return nav
        case let .giftToUser(dependency, delegate):
            let vc = RCSceneGiftViewController(dependency: dependency, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .gift(dependency, delegate):
            let vc = RCGameSceneGiftViewController(dependency: dependency, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .voiceRoomAlert(title, actions, alertType, delegate):
            let vc = VoiceRoomAlertViewController(title: title, actions: actions, alertType: alertType, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .leaveAlert(isOwner, delegate):
            let vc = VoiceRoomLeaveAlertViewController(isOwner: isOwner, delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .notice(modify, notice ,delegate):
            let vc = VoiceRoomNoticeViewController(modify: modify, notice: notice, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .forbiddenList(roomId):
            let vc = VoiceRoomForbiddenViewController(roomId: roomId)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        case let .switchGame(games, delegate):
            let vc = GameSwitchSelectViewController(games: games, delegate: delegate)
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            return vc
        case let .onSeatUserOperation(bottomButtons, gameSeatUser, delegate, canSetManager):
            let vc = OnSeatUserOperationController(bottomButtons: bottomButtons, gameSeatUser: gameSeatUser, delegate: delegate, canSetManager: canSetManager)
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .popover
            return vc
        }
    }
}

extension UIViewController {
    @discardableResult
    func navigator(_ navigation: RCNavigation) -> UIViewController {
        return navigate(navigation as Navigation)
    }
}
