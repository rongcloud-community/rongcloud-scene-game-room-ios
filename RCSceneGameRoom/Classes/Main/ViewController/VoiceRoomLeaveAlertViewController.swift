//
//  VoiceRoomLeaveAlertViewController.swift
//  RCE
//
//  Created by shaoshuai on 2021/6/9.
//

import UIKit
import RCSceneRoom

final class VoiceRoomLeaveAlertViewController: UIViewController {
    private weak var delegate: RCSceneLeaveViewProtocol?
    private lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .regular)
        let instance = UIVisualEffectView(effect: effect)
        return instance
    }()
    private lazy var container: UIView = {
        let instance = UIView()
        instance.backgroundColor = .clear
        instance.layer.cornerRadius = 22
        instance.clipsToBounds = true
        return instance
    }()
    private lazy var quitButton: UIButton = {
        let instance = UIButton()
        instance.setBackgroundImage(RCSCAsset.Images.leaveVoiceroom.image, for: .normal)
        instance.addTarget(self, action: #selector(handleQuitDidClick), for: .touchUpInside)
        return instance
    }()
    private lazy var quitLabel: UILabel = {
        let instance = UILabel()
        instance.textColor = UIColor.white
        instance.font = .systemFont(ofSize: 12.resize)
        instance.text = "离开房间"
        return instance
    }()
    private lazy var closeButton: UIButton = {
        let instance = UIButton()
        instance.setBackgroundImage(RCSCAsset.Images.closeVoiceroom.image, for: .normal)
        instance.addTarget(self, action: #selector(handleCloseDidClick), for: .touchUpInside)
        return instance
    }()
    private lazy var closeLabel: UILabel = {
        let instance = UILabel()
        instance.textColor = UIColor.white
        instance.font = .systemFont(ofSize: 12.resize)
        instance.text = "关闭房间"
        return instance
    }()
   
    private lazy var upIconImageView = UIImageView(image: RCSCAsset.Images.leaveRoomUpIcon.image)
    private lazy var tapGestureView = UIView()
    private let isOwner: Bool
    
    init(isOwner: Bool, _ delegate: RCSceneLeaveViewProtocol) {
        self.isOwner = isOwner
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        show()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismiss()
    }
    
    private func buildLayout() {
        view.addSubview(tapGestureView)
        tapGestureView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(container)
        container.addSubview(blurView)
        container.addSubview(quitButton)
        container.addSubview(quitLabel)
        container.addSubview(closeButton)
        container.addSubview(closeLabel)
        container.addSubview(upIconImageView)
        
        container.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(142.resize)
        }
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        if isOwner {
            quitButton.snp.makeConstraints {
                $0.width.height.equalTo(50.resize)
                $0.bottom.equalToSuperview().offset(-61.resize)
                $0.right.equalTo(container.snp_centerX).offset(-60)
            }
            
            quitLabel.snp.makeConstraints { make in
                make.centerX.equalTo(quitButton)
                make.bottom.equalToSuperview().offset(-37.resize)
            }
        
            closeButton.snp.makeConstraints { make in
                make.left.equalTo(container.snp_centerX).offset(60)
                make.width.height.equalTo(50.resize)
                make.bottom.equalToSuperview().offset(-61.resize)
            }
            
            closeLabel.snp.makeConstraints { make in
                make.centerX.equalTo(closeButton)
                make.bottom.equalToSuperview().offset(-37.resize)
            }
        } else {
            quitButton.snp.makeConstraints {
                $0.width.height.equalTo(50.resize)
                $0.bottom.equalToSuperview().offset(-61.resize)
                $0.centerX.equalToSuperview()
            }
            
            quitLabel.snp.makeConstraints { make in
                make.centerX.equalTo(quitButton)
                make.bottom.equalToSuperview().offset(-37.resize)
            }
        }
        
        
        upIconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-7.resize)
            make.width.height.equalTo(27.resize)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        tapGestureView.addGestureRecognizer(tapGesture)
    }

    @objc func handleCloseDidClick() {
        dismiss(animated: false) {
            DispatchQueue.main.async {
                self.delegate?.closeRoomDidClick()
            }
        }
    }
    
    @objc func handleQuitDidClick() {
        dismiss(animated: true, completion: nil)
        delegate?.quitRoomDidClick()
    }
    
    @objc func handleViewTap() {
        dismiss(animated: true, completion: nil)
    }
        
    private func show() {
        container.transform = CGAffineTransform(translationX: 0, y: -142.resize)
        UIView.animate(withDuration: 0.2) {
            self.container.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2) {
            self.container.transform = CGAffineTransform(translationX: 0, y: -142.resize)
        }
    }
}
