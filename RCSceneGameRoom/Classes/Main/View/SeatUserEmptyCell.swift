//
//  SeatUserEmptyCell.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/23.
//

import Reusable
import Pulsator
import RCSceneRoom
import UIKit


class SeatUserEmptyCell: UICollectionViewCell, Reusable {
    
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
    
    private lazy var muteMicrophoneImageView: UIImageView = {
        let instance = UIImageView()
        instance.contentMode = .scaleAspectFit
        instance.image = RCSCAsset.Images.muteMicrophoneIcon.image
        instance.isHidden = true
        return instance
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(backGroundImageView)
        contentView.addSubview(statusImageView)
        contentView.addSubview(muteMicrophoneImageView)
        
        backGroundImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        statusImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        muteMicrophoneImageView.snp.makeConstraints {
            $0.bottom.right.equalToSuperview()
            $0.size.equalTo(CGSize(width: 14, height: 14))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        muteMicrophoneImageView.isHidden = true
    }
    
    func update(user: RCGameSeatUser, voiceSeatInfo: RCVoiceSeatInfo) {
        muteMicrophoneImageView.isHidden = !voiceSeatInfo.isMuted
        if voiceSeatInfo.status == .locking {
            statusImageView.image = RCSCGameRoomAsset.seatStateLock.image
        } else {
            statusImageView.image = RCSCGameRoomAsset.seatMicIcon.image
        }
        
        self.addBorderGradient(to: backGroundImageView,
                               startColor: UIColor.white,
                               endColor: UIColor.white,
                               lineWidth: 0.8,
                               startPoint: CGPoint.topLeft,
                               endPoint: CGPoint.bottomRight)
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
