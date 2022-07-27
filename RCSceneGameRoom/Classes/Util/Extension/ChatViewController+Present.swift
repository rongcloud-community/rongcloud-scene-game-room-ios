//
//  ChatViewController+Present.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/7/27.
//

import Foundation

extension ChatViewController {
    static func presenting(_ controller: UIViewController, userId: String) {
        let vc = ChatListViewController(.ConversationType_PRIVATE)
        vc.canCallComing = false
        let navigation = UINavigationController(rootViewController: vc)
        navigation.modalTransitionStyle = .coverVertical
        navigation.modalPresentationStyle = .overFullScreen
        vc.navigationItem.leftBarButtonItem = {
            let image = RCSCAsset.Images.backIndicatorImage.image
            let action = #selector(navigationWarpBackTrigger)
            let instance = UIBarButtonItem(image: image,
                                           style: .plain,
                                           target: navigation,
                                           action: action)
            return instance
        }()
        let chatController = ChatViewController(.ConversationType_PRIVATE, userId: userId)
        navigation.pushViewController(chatController, animated: false)
        controller.present(navigation, animated: true)
    }
}
