// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum RCSCGameRoomAsset {
  public static let bottomBarBackground = ImageAsset(name: "bottom_bar_background")
  public static let captainBg = ImageAsset(name: "captain_bg")
  public static let changeMeEnterSeat = ImageAsset(name: "change_me_enter_seat")
  public static let closeMsgBoard = ImageAsset(name: "close_msg_board")
  public static let enterMessage = ImageAsset(name: "enter_message")
  public static let gamePlayingBg = ImageAsset(name: "game_playing_bg")
  public static let gameStateBackgroud = ImageAsset(name: "game_state_backgroud")
  public static let inviteSeatAction = ImageAsset(name: "invite_seat_action")
  public static let inviteUserGame = ImageAsset(name: "invite_user_game")
  public static let kickSeatAction = ImageAsset(name: "kick_seat_action")
  public static let kickUserFromRoom = ImageAsset(name: "kick_user_from_room")
  public static let kickUserLeaveGame = ImageAsset(name: "kick_user_leave_game")
  public static let messageBackground = ImageAsset(name: "message_background")
  public static let micClose = ImageAsset(name: "mic_close")
  public static let micInput = ImageAsset(name: "mic_input")
  public static let micInputIcon = ImageAsset(name: "mic_input_icon")
  public static let micOpen = ImageAsset(name: "mic_open")
  public static let openMsgBoard = ImageAsset(name: "open_msg_board")
  public static let pickUsers = ImageAsset(name: "pick_users")
  public static let roomNoticeIcon = ImageAsset(name: "room_notice_icon")
  public static let roomOnlineUser = ImageAsset(name: "room_online_user")
  public static let seatCellBackgroud = ImageAsset(name: "seat_cell_backgroud")
  public static let seatMicIcon = ImageAsset(name: "seat_mic_icon")
  public static let seatStateLock = ImageAsset(name: "seat_state_lock")
  public static let settingIcon = ImageAsset(name: "setting_icon")
  public static let singleMessageBg = ImageAsset(name: "single_message_bg")
  public static let switchGameBackgroud = ImageAsset(name: "switch_game_backgroud")
  public static let switchGameDownFlag = ImageAsset(name: "switch_game_down_flag")
  public static let topBarBackground = ImageAsset(name: "top_bar_background")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
    let bundle = RCSCGameRoomPod.resourcesBundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = RCSCGameRoomPod.resourcesBundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif
}

public extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = RCSCGameRoomPod.resourcesBundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}
