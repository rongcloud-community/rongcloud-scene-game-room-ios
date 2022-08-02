//
//  GameRoomViewController.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/20.
//

import Kingfisher
import RCSceneRoom
import UIKit
import RCSceneRoom
import RCSceneKit

let alertTypeVideoAlreadyClose = "alertTypeVideoAlreadyClose"
let alertTypeConfirmCloseRoom = "alertTypeConfirmCloseRoom"

struct managersWrapper: Codable {
    let code: Int
    let data: [RCSceneRoomUser]?
}


class GameRoomViewController: UIViewController {
    dynamic var kvRoomInfo: RCVoiceRoomInfo?
    dynamic var voiceRoomInfo: RCSceneRoom
    
    var voiceRoomSeats: [RCVoiceSeatInfo] = [RCVoiceSeatInfo]()
    var gameSeatUsers = [RCGameSeatUser]()
    var onPlaySeatUsers = [String]()
    var onReadyGameUsers = [String]()
    var captainUserId: String?

    dynamic var managers = [RCSceneRoomUser]()
    
    dynamic var userGiftInfo = [String: Int]()
    
    dynamic var roomState: RoomSettingState
    
    dynamic var isRoomClosed = false

    let musicInfoBubbleView = RCMusicEngine.musicInfoBubbleView
    
    let isCreate: Bool
    var isFastIn: Bool = false
    
    let pickDownBtn = OnSeatUserAction.pickDown.button
    let lockSeatBtn = OnSeatUserAction.lockSeat.button
    let muteBtn = OnSeatUserAction.mute.button
    let kickOutBtn = OnSeatUserAction.kickOut.button
    let inviteGameBtn = OnSeatUserAction.inviteGame.button
    let kickOutGameBtn = OnSeatUserAction.kickOutGame.button
    
    let forbidSeatBtn = MasterSeatUserAction.forbiddenSeat.button
    let masterMicStateBtn = MasterSeatUserAction.micState.button
    let leaveSeatBtn = MasterSeatUserAction.leaveSeat.button
    
    var currentUserOperationVc: OnSeatUserOperationController?
    var currentMasterOperationVc: MasterSeatOperationViewController?
    
    
    private lazy var topBlurView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleToFill
        instance.image = RCSCGameRoomAsset.topBarBackground.image
        return instance
    }()
    
    public lazy var topContainerView: UIView = {
        let instance = UIView()
        instance.backgroundColor = .clear
        instance.isHidden = true
        return instance
    }()
    

    private(set) lazy var roomInfoView = SceneRoomInfoView(voiceRoomInfo)

    public lazy var switchGameView: SwitchGameActionView = {
        let instance = SwitchGameActionView()
        instance.isHidden = true
        return instance
    }()
    
    public lazy var roomNoticeButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = .clear
        instance.setBackgroundImage(RCSCGameRoomAsset.roomNoticeIcon.image, for: .normal)
        return instance
    }()
    
    public lazy var moreButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = .clear
        instance.setBackgroundImage(RCSCAsset.Images.moreIcon.image, for: .normal)
        return instance
    }()
    

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let instance = UICollectionView(frame: .zero, collectionViewLayout: layout)
        instance.register(cellType: SeatUserViewCell.self)
        instance.register(cellType: SeatUserEmptyCell.self)
        instance.backgroundColor = .clear
        instance.showsHorizontalScrollIndicator = false
        instance.delegate = self
        instance.dataSource = self
        instance.isScrollEnabled = true;
        return instance
    }()

    
    private(set) lazy var backgroundImageView: AnimatedImageView = {
        let instance = AnimatedImageView()
        instance.contentMode = .scaleAspectFill
        instance.clipsToBounds = true
        instance.runLoopMode = .default
        return instance
    }()
    
    private(set) lazy var chatroomView = RCChatroomSceneView()
    
    private(set) lazy var micStateButton = UIButton(type: .custom)
    private(set) lazy var pickUsersButton = RCChatroomSceneButton(.pickUser)
    private(set) lazy var giftButton = RCChatroomSceneButton(.gift)
    private(set) lazy var messageButton = RCChatroomSceneButton(.message)
    private(set) lazy var settingButton = RCChatroomSceneButton(.setting)
    
    var messageView: RCChatroomSceneMessageView {
        return chatroomView.messageView
    }
 
    public var userViewPopListVc: UserListViewController?
    
    
    private lazy var bottomBlurView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleToFill
        instance.image = RCSCGameRoomAsset.bottomBarBackground.image
        return instance
    }()
    
    public lazy var bottomContainerView: UIView = {
        let instance = UIView()
        instance.backgroundColor = .clear
        instance.isHidden = true
        return instance
    }()
    
    
    public lazy var messageLabel: MessageOneLine = {
        return MessageOneLine()
    }()
    
    
    public lazy var msgBoardOpenButton: UIButton = {
        let instance = UIButton()
        instance.backgroundColor = .clear
        instance.setBackgroundImage(RCSCGameRoomAsset.openMsgBoard.image, for: .normal)
        return instance
    }()

    
    public lazy var msgBoardView: MessageBoardView = {
        let instance = MessageBoardView(messageView: self.messageView) {
            self.msgBoardOpenButton.isHidden = false
            self.messageLabel.isHidden = false
        }
        return instance
    }()
    
    var toolBarView: RCChatroomSceneToolBar {
        let tooBar = chatroomView.toolBar
        return tooBar
    }
    

    private var preloadBgImage: UIImage?
    
    var currentGameState: RCGameState = .IDLE
    var gameSwitching: Bool = false
    
    var switchNewGame: RCSceneGameResp?
    
    var inviteGameAlert: UIAlertController?
    var inviteVoiceAlert: UIAlertController?
        
    var onKeyword: String?
    var isPushAudioData: Bool = false

    init(roomInfo: RCSceneRoom, isCreate: Bool = false) {
        voiceRoomInfo = roomInfo
        self.isCreate = isCreate
        roomState = RoomSettingState()
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        RCVoiceRoomEngine.sharedInstance().setDelegate(self)
        /**TO BE FIX 后续用新的router替换*/
        Router.default.setupAppNavigation(appNavigation: RCAppNavigation())
    }
    
    convenience init(roomInfo: RCSceneRoom, isCreate: Bool = false, preloadBgImage: UIImage?, switchNewGame: RCSceneGameResp?) {
        self.init(roomInfo: roomInfo, isCreate: isCreate)
        self.preloadBgImage = preloadBgImage
        self.switchNewGame = switchNewGame
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("voice room deinit")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVoiceRoom()
        buildLayout()
        setupModules()
        addObserver()
        bubbleViewAddGesture()
        UserDefaults.standard.increaseFeedbackCountdown()
        if (!voiceRoomInfo.isOwner) {
            RCSMusicDataSource.instance.fetchRoomPlayingMusicInfo { info in
                self.musicInfoBubbleView?.info = info;
            }
        }
        RCIM.shared().addReceiveMessageDelegate(self)
        RCSceneMusic.join(voiceRoomInfo, bubbleView: musicInfoBubbleView!)
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if parent == nil {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
        messageButton.refreshMessageCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if parent == nil {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    func roomContainerSwitchRoom(_ room: RCSceneRoom) {
        guard let containerVC = self.parent as? RCSPageContainerController else { return }
        
        if SceneRoomManager.shared.currentRoom?.roomType == room.roomType {
            if let index = containerVC.pageItems.firstIndex(where: { $0.pageId == room.roomId }) {
                containerVC.currentIndex = index
                return
            }
        }
        let item = RCSPageModel()
        item.switchable = room.switchable
        item.pageId = room.roomId
        item.backgroudUrl = room.backgroundUrl
        containerVC.pageItems = [item]
        containerVC.reloadData()
        containerVC.currentIndex = 0
        containerVC.setScrollable(false)
    }
    
    
    private func buildLayout() {
        view.backgroundColor = .clear
        view.addSubview(backgroundImageView)
        view.addSubview(topBlurView)
        view.addSubview(topContainerView)
        
        topContainerView.addSubview(roomInfoView)
        topContainerView.addSubview(switchGameView)
        topContainerView.addSubview(roomNoticeButton)
        topContainerView.addSubview(moreButton)
        topContainerView.addSubview(collectionView)
        
        view.addSubview(msgBoardView)
        
        view.addSubview(bottomBlurView)
        view.addSubview(bottomContainerView)
        
        bottomContainerView.addSubview(messageLabel)
        bottomContainerView.addSubview(msgBoardOpenButton)
        bottomContainerView.addSubview(toolBarView)

        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if let bgImage = self.preloadBgImage {
            backgroundImageView.image = bgImage
        }
        
        
        topContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(9)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(112)
        }
        
        topBlurView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(topContainerView)
        }
        
        roomInfoView.snp.makeConstraints {
            $0.top.left.equalToSuperview()
        }
        
        switchGameView.snp.makeConstraints {
            $0.centerY.equalTo(roomInfoView)
            $0.left.equalTo(roomInfoView.snp_right).offset(10)
            $0.height.equalTo(22)
        }
        
        moreButton.snp.makeConstraints {
            $0.centerY.equalTo(roomInfoView)
            $0.right.equalToSuperview().inset(12.resize)
        }
        
        roomNoticeButton.snp.makeConstraints { make in
            make.right.equalTo(moreButton.snp.left).offset(-12)
            make.centerY.equalTo(moreButton.snp.centerY)
            make.size.equalTo(CGSize(width: 19, height: 22))
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(roomInfoView.snp.bottom).offset(10)
            $0.left.right.equalToSuperview().offset(10)
            $0.height.equalTo(60)
        }
        
        bottomContainerView.snp.makeConstraints {
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(85)
        }
        
        bottomBlurView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(bottomContainerView)
        }
        
        msgBoardOpenButton.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.right.equalToSuperview().offset(-12)
        }
        
        
        messageLabel.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.height.equalTo(45)
            $0.width.equalTo(210)
            $0.centerY.equalTo(msgBoardOpenButton)
        }
        
        toolBarView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(44)
        }
        
    
        msgBoardView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(view.snp.bottom).offset(messageBoardHeight)
            $0.height.equalTo(messageBoardHeight)
        }
    
        guard let bubble = musicInfoBubbleView else {
            return
        }
        view.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.top.equalTo(moreButton.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 60, height: 50))
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(noti:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func bubbleViewAddGesture() {
        guard let bubble = musicInfoBubbleView else {
            return
        }
        
        for v in bubble.subviews {
            if let marqueeClass = NSClassFromString("UUMarqueeView") {
                if v.isKind(of: marqueeClass) {
                    v.isHidden = true
                }
            }
        }
        bubble.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action:#selector(presentMusicController))
        bubble.addGestureRecognizer(tap)
    }
    
    @objc func presentMusicController() {
        //观众不展示音乐列表
        if (!self.voiceRoomInfo.isOwner) {return}
        RCMusicEngine.shareInstance().show(in: self, completion: nil)
    }
    
    @objc private func handleNotification(noti: Notification) {
        // 已关闭房间，应用切回前台
        if isRoomClosed, let vc = UIApplication.shared.topmostController(), vc == self {
            navigator(.voiceRoomAlert(title: "房主已关闭房间", actions: [.confirm("确定")], alertType: alertTypeVideoAlreadyClose, delegate: self))
        }
    }
    
    //MARK: - dynamic funcs
    ///设置模块，在viewDidLoad中调用
    dynamic func setupModules() {}
    ///消息回调，在engine模块中触发
    dynamic func handleReceivedMessage(_ message: RCMessage) {}
}

extension GameRoomViewController {
    private func setupVoiceRoom() {
        guard let voiceRoomGameInfo = voiceRoomInfo.gameResp else {
            return
        }
        SVProgressHUD.show()
        var roomKVInfo: RCVoiceRoomInfo?
        if isCreate {
            let kvRoom = RCVoiceRoomInfo()
            kvRoom.roomName = voiceRoomInfo.roomName
            kvRoom.isFreeEnterSeat = true
            kvRoom.seatCount = (voiceRoomGameInfo.maxSeat <= 9) ? 9 : voiceRoomGameInfo.maxSeat
            roomKVInfo = kvRoom
        }

        RCRTCEngine.sharedInstance().defaultAudioStream.recordAudioDataCallback = { audioFrame in
            if self.isPushAudioData {
                DispatchQueue.main.async {
                    let data = NSData(bytes: audioFrame.bytes, length: Int(audioFrame.length))
                    self.drawAndGuessPushAudio(data: data)
                }
            }
        }

        moreButton.isEnabled = false
        SceneRoomManager.shared
            .voice_join(voiceRoomInfo.roomId, roomKVInfo: roomKVInfo) { [weak self] result in
                guard let self = self else { return }
                self.moreButton.isEnabled = true
                switch result {
                case .success:
                    SVProgressHUD.dismiss()
                    SceneRoomManager.shared.currentRoom = self.voiceRoomInfo
                  
                    if let switchNewGame = self.switchNewGame {
                        if self.voiceRoomInfo.gameResp?.maxSeat != switchNewGame.maxSeat {
                            let roomInfo = RCVoiceRoomInfo()
                            roomInfo.roomName = self.voiceRoomInfo.roomName
                            roomInfo.isFreeEnterSeat = true
                            roomInfo.seatCount = (switchNewGame.maxSeat <= 9) ? 9 : switchNewGame.maxSeat
                    
                            RCVoiceRoomEngine.sharedInstance().setRoomInfo(roomInfo) {
                                self.kvRoomInfo = roomInfo
                                self.enterRoomHandleSwitch(newGame: switchNewGame)
                            } error: { _, _ in }
                        } else {
                            self.enterRoomHandleSwitch(newGame: switchNewGame)
                        }
                    } else {
                        self.prepareGameEngine(gameInfo: self.voiceRoomInfo.gameResp)
                    }
                    self.sendJoinRoomMessage()
                case let .failure(error):
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            }
    }
    
    
    func enterRoomHandleSwitch(newGame: RCSceneGameResp) {
        self.voiceRoomInfo.gameResp = newGame
        self.prepareGameEngine(gameInfo: newGame)
        self.reportSwitchGame(gameId: newGame.gameId)
        guard let encodedData = try? JSONEncoder().encode(newGame) else {
            return
        }
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            return
        }
        VoiceRoomNotification.switchGame.send(content: jsonString)
    }

    
    func leaveRoom() {
        clearMusicData()
        SVProgressHUD.show()
        SceneRoomManager.shared
            .voice_leave { [weak self] result in
                SceneRoomManager.shared.currentRoom = nil
                RCSPageFloaterManager.shared().hide()
                SVProgressHUD.dismiss()
                switch result {
                case .success:
                    print("leave room success")
                    RCGameEngine.shared().destroy()
                    self?.backgroundImageView.isHidden = false
                    self?.backTrigger()
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
    }
    
    /// 关闭房间
    func closeRoom() {
        SVProgressHUD.show()
        voiceRoomService.closeRoom(roomId: voiceRoomInfo.roomId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                SVProgressHUD.dismiss()
                switch result.map(RCSceneResponse.self) {
                case let .success(response):
                    if response.validate() {
                        self?.leaveRoom()
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "关闭房间失败")
                    }
                case .failure:
                    SVProgressHUD.showSuccess(withStatus: "关闭房间失败")
                }
            }
        }
    }
    
    func clearMusicData() {
        if (self.voiceRoomInfo.isOwner) {
            RCSceneMusic.clear()
        }
    }
}

extension GameRoomViewController {
    func currentUserRole() -> SceneRoomUserType {
        if currentLoginUser() == voiceRoomInfo.userId {
            return .creator
        }
        if managers.contains(where: { currentLoginUser() == $0.userId }) {
            return .manager
        }
        return .audience
    }
    
    func currentLoginUser() -> String {
       return Environment.currentUserId  
    }
    
    var enableMic: Bool {
        guard let seat = self.voiceRoomSeats.first(where: { $0.userId == Environment.currentUserId }) else { return false
        }
        if RCVoiceRoomEngine.sharedInstance().isDisableAudioRecording() {
            return false
        }
        return !seat.isMuted
    }
}

extension GameRoomViewController: RCIMReceiveMessageDelegate {
    func onRCIMCustomAlertSound(_ message: RCMessage!) -> Bool {
        return true
    }
}
