//
//  GameSwitchSelectViewController.swift
//  RCSceneGameRoom
//
//  Created by johankoi on 2022/6/4.
//

import UIKit
import RCSceneRoom

protocol GameSwitchSelectDelegate: AnyObject {
    func didSelectForSwitch(game: RCSceneGameResp)
}


class GameSwitchSelectViewController: UIViewController {
    
    private weak var delegate: GameSwitchSelectDelegate?
    
    private var games: [RCSceneGameResp] = [RCSceneGameResp]()

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
    
    
    private lazy var tapGestureView: UIView = {
        let instance = UIView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        instance.addGestureRecognizer(tapGesture)
        return instance
    }()
    
    private lazy var gamesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 25
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        let instance = UICollectionView(frame: .zero, collectionViewLayout: layout)
        instance.showsVerticalScrollIndicator = false
        instance.showsHorizontalScrollIndicator = false
        instance.dataSource = self
        instance.delegate = self
        instance.backgroundColor = .clear
        instance.register(cellType: RCSelectGameItemCell.self)
        return instance
    }()
    

    public init(games: [RCSceneGameResp], delegate: GameSwitchSelectDelegate?) {
        self.games = games
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    
        gameRoomProvider.request(.gameList) { result in
            switch result.map(RCSceneWrapper<[RCSceneGameResp]>.self) {
            case let .success(wrapper):
                if let list = wrapper.data {
                    self.games = list
                    self.gamesCollectionView.reloadData()
                }
            case let .failure(error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    private func buildLayout() {
        view.addSubview(tapGestureView)
        view.addSubview(container)
        container.addSubview(blurView)
        container.addSubview(gamesCollectionView)
          
        tapGestureView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        container.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(200.resize)
        }
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        gamesCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    private func show() {
        container.transform = CGAffineTransform(translationX: 0, y: -200.resize)
        UIView.animate(withDuration: 0.2) {
            self.container.transform = .identity
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.2) {
            self.container.transform = CGAffineTransform(translationX: 0, y: -200.resize)
        }
    }
    
    @objc func handleViewTap() {
        dismiss(animated: true, completion: nil)
    }
}



extension GameSwitchSelectViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let numberOfItemsPerRow: CGFloat = 4
        let spacing: CGFloat = (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        let availableWidth = width - spacing * (numberOfItemsPerRow + 1)
        let itemDimension = floor(availableWidth / numberOfItemsPerRow)
        return CGSize(width: itemDimension, height: itemDimension + 10)
    }
}

extension GameSwitchSelectViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: RCSelectGameItemCell.self)
        cell.updateCell(item: games[indexPath.row])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }
}

extension GameSwitchSelectViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectForSwitch(game: games[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}
