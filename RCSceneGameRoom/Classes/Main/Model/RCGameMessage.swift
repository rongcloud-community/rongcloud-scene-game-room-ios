//
//  RCGameMessage.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/21.
//

import UIKit

class RCGameMessage: NSObject {
    var attributedMessage: NSAttributedString?
  
    override init() {
        super.init()
    }

    convenience init(attributedMessage: NSAttributedString) {
        self.init()
        self.attributedMessage = attributedMessage
    }
}


extension RCGameMessage: RCChatroomSceneMessageProtocol {
    func attributeString() -> NSAttributedString {
        return self.attributedMessage ?? NSAttributedString(string: " ")
    }
}
 
