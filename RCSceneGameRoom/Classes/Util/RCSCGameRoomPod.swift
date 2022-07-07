//
//  RCSCGameRoomPod.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/5/25.
//

import Foundation

final class RCSCGameRoomPod {
  // This is the bundle where your code resides in
  static let bundle = Bundle(for: RCSCGameRoomPod.self)

  // Your resources bundle is inside that bundle
  static let resourcesBundle: Bundle = {
    guard let url = bundle.url(forResource: "RCSceneGameRoom", withExtension: "bundle"),
      let bundle = Bundle(url: url) else {
      fatalError("Can't find 'RCSceneGameRoom' bundle")
    }
    return bundle
  }()
}
