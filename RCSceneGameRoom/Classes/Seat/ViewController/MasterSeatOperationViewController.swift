//
//  OwnerSeatPopViewController.swift
//  RCE
//
//  Created by 叶孤城 on 2021/5/11.
//

import UIKit

class MasterSeatOperationViewController: UIViewController {
    
    public let gameSeatUser: RCGameSeatUser
    private var sheetActions: [UIButton]?
    
    private lazy var popView: OwnerSeatPopView = {
        let seatPopView = OwnerSeatPopView(actions: self.sheetActions)
        return seatPopView
    }()
    
    
    init(gameSeatUser: RCGameSeatUser, actions: [UIButton]?) {
        self.gameSeatUser = gameSeatUser
        self.sheetActions = actions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableClickingDismiss()
        
        view.addSubview(popView)
        
        popView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(280)
        }
        RCSceneUserManager.shared.fetchUserInfo(userId: gameSeatUser.userId!) { [weak self] user in
            self?.popView.updateView(user: user)
        }
    }

   
}
