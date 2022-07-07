//
//  VoiceRoomSeatCollectionViewCell.swift
//  RCE
//
//  Created by 叶孤城 on 2021/4/20.
//

import UIKit
import Reusable
import Pulsator
import RCSceneRoom
import Kingfisher
import SDWebImage

extension CGPoint {
    static let topLeft = CGPoint(x: 0, y: 0)
    static let topCenter = CGPoint(x: 0.5, y: 0)
    static let topRight = CGPoint(x: 1, y: 0)
    static let centerLeft = CGPoint(x: 0, y: 0.5)
    static let center = CGPoint(x: 0.5, y: 0.5)
    static let centerRight = CGPoint(x: 1, y: 0.5)
    static let bottomLeft = CGPoint(x: 0, y: 1.0)
    static let bottomCenter = CGPoint(x: 0.5, y: 1.0)
    static let bottomRight = CGPoint(x: 1, y: 1)
}

class SeatUserViewCell: UICollectionViewCell, Reusable {
    
    private var voiceSeatInfo: RCVoiceSeatInfo?
    private var user: RCSceneRoomUser?

    private lazy var backGroundImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        instance.image = RCSCGameRoomAsset.seatCellBackgroud.image
        return instance
    }()
    
    private lazy var statusImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCGameRoomAsset.seatMicIcon.image
        return instance
    }()

    
    private lazy var radarView: Pulsator = {
        let instance = Pulsator()
        instance.numPulse = 4
        instance.radius = 33
        instance.animationDuration = 1
        instance.pulseInterval = 0.3
        instance.backgroundColor = UIColor.purple.alpha(1.0).cgColor
        return instance
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFill
        let bounds = CGRect(x: 0, y: 0, width: 50, height: 50)
        let maskPath = UIBezierPath(roundedRect:bounds , cornerRadius: 25)
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.frame = bounds
        instance.layer.mask = maskLayer;
        return instance
    }()

    private lazy var gameStatusView: BackgroundTextLabel = {
        let instance = BackgroundTextLabel()
        instance.update(image: RCSCGameRoomAsset.gameStateBackgroud.image, text: nil)
        instance.isHidden = true
        return instance
    }()
    
    private lazy var muteMicrophoneImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCAsset.Images.muteMicrophoneIcon.image
        instance.isHidden = true
        return instance
    }()
    
    private lazy var captainFlagView: BackgroundTextLabel = {
        let instance = BackgroundTextLabel()
        instance.update(image: RCSCGameRoomAsset.captainBg.image, text: "队长")
        instance.isHidden = true
        return instance
    }()
    
    private var seatInfo: RCVoiceSeatInfo?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.insertSublayer(radarView, at: 0)

        contentView.addSubview(backGroundImageView)
        contentView.addSubview(statusImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(gameStatusView)
        contentView.addSubview(muteMicrophoneImageView)
        contentView.addSubview(captainFlagView)
        
        
        backGroundImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 50, height: 50))
            $0.center.equalToSuperview()
        }
        
        statusImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        avatarImageView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 50, height: 50))
            $0.center.equalToSuperview()
        }
    
        gameStatusView.snp.makeConstraints {
            $0.top.equalTo(avatarImageView.snp_bottom).offset(-10)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(CGSize(width: 32, height: 11))
        }
        
        captainFlagView.snp.makeConstraints {
            $0.top.right.equalToSuperview()
            $0.size.equalTo(CGSize(width: 30, height: 14.5))
        }
        
        muteMicrophoneImageView.snp.makeConstraints {
            $0.bottom.right.equalToSuperview()
            $0.size.equalTo(CGSize(width: 14, height: 14))
        }
     
        radarView.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        radarView.position = contentView.center

    }
 
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        radarView.stop()
        captainFlagView.isHidden = true
        muteMicrophoneImageView.isHidden = true
        gameStatusView.isHidden = true
        self.avatarImageView.image = nil
        self.avatarImageView.sd_cancelCurrentImageLoad()
        print("SeatUserViewCell prepareForReuse")

    }
    
    
    func update(user: RCGameSeatUser, voiceSeatInfo: RCVoiceSeatInfo) {
        self.voiceSeatInfo = voiceSeatInfo
        
        if user.state == .prepared {
            gameStatusView.update(image: RCSCGameRoomAsset.gameStateBackgroud.image, text: "已准备")
        } else if user.state == .playing {
            gameStatusView.update(image: RCSCGameRoomAsset.gamePlayingBg.image, text: "游戏中")
        } else {
            gameStatusView.isHidden = true
        }
        
        captainFlagView.isHidden = !(user.isCaptain ?? false)
        muteMicrophoneImageView.isHidden = !voiceSeatInfo.isMuted
        
        if voiceSeatInfo.status == .locking {
            statusImageView.image = RCSCGameRoomAsset.seatStateLock.image
        } else {
            statusImageView.image = RCSCGameRoomAsset.seatMicIcon.image
        }
        
        if let userId = user.userId {
            RCSceneUserManager.shared.refreshUserInfo(userId: userId) { [weak self] userInfo in
                guard let portraitUrl = URL(string: userInfo.portraitUrl)  else {
                    return
                }
                self?.avatarImageView.sd_setImage(with: portraitUrl, completed: { image, err, cacheType, url in
                    self?.addBorderGradient(to: self?.avatarImageView,
                                      startColor: UIColor(hexString: "0xEF308A"),
                                      endColor: UIColor(hexString: "0x6162E8"),
                                      lineWidth: 6,
                                      startPoint: CGPoint.topLeft,
                                      endPoint: CGPoint.bottomRight)
                })
                
            }
        }

    }
    
    func setSpeakingState(isSpeaking: Bool) {
        let isMuted = self.voiceSeatInfo?.isMuted ?? true
        
        guard isSpeaking, self.voiceSeatInfo?.status == .using, !isMuted else {
            self.radarView.stop()
            return
        }
        if !radarView.isPulsating {
            radarView.start()
        }
    }
        
    func addBorderGradient(to view: UIView?, startColor:UIColor, endColor: UIColor, lineWidth: CGFloat, startPoint: CGPoint, endPoint: CGPoint) {
        guard let view = view else { return }
        //This will make view border circular
        view.layer.cornerRadius = view.bounds.size.height / 2.0
        //This will hide the part outside of border, so that it would look like circle
        view.clipsToBounds = true
        //Create object of CAGradientLayer
        let gradient = CAGradientLayer()
        //Assign origin and size of gradient so that it will fit exactly over circular view
        gradient.frame = view.bounds
        //Pass the gredient colors list to gradient object
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        //Point from where gradient should start
        gradient.startPoint = startPoint
        //Point where gradient should end
        gradient.endPoint = endPoint
        //Now we have to create a circular shape so that it can be added to view’s layer
        let shape = CAShapeLayer()
        //Width of circular line
        shape.lineWidth = lineWidth
        //Create circle with center same as of center of view, with radius equal to half height of view, startAngle is the angle from where circle should start, endAngle is the angle where circular path should end
        shape.path = UIBezierPath(
        arcCenter: CGPoint(x: view.bounds.height/2,
        y: view.bounds.height/2),
        radius: view.bounds.height/2,
        startAngle: CGFloat(0),
        endAngle:CGFloat(CGFloat.pi * 2),
        clockwise: true).cgPath
        //the color to fill the path’s stroked outline
        shape.strokeColor = UIColor.black.cgColor
        //The color to fill the path
        shape.fillColor = UIColor.clear.cgColor
        //Apply shape to gradient layer, this will create gradient with circular border
        gradient.mask = shape
        //Finally add the gradient layer to out View
        view.layer.addSublayer(gradient)
    }
}
