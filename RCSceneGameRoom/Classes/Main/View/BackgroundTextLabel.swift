
import UIKit

class BackgroundTextLabel: UIView {
    
    private lazy var bgImageView: UIImageView = {
        let instance = UIImageView()
        return instance
    }()
    
    private lazy var contentLabel: UILabel = {
        let instance = UILabel()
        instance.font = .systemFont(ofSize: 9)
        instance.textColor = UIColor.white.withAlphaComponent(0.8)
        instance.backgroundColor = .clear
        instance.textAlignment = .center
        return instance
    }()
    
    private var textInset: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bgImageView.addSubview(contentLabel)
        addSubview(bgImageView)
       
        bgImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    convenience init(frame: CGRect, textInset: CGFloat?) {
        self.init(frame: frame)
        self.textInset = textInset
    }
    
    func update(image: UIImage?, text: String?) {
        self.isHidden = false
        if let image = image {
            bgImageView.image = image
        }
        if let text = text {
            contentLabel.text = text;
        }
        
        contentLabel.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            if let inset = self.textInset {
                $0.left.equalToSuperview().offset(inset)
                $0.right.equalToSuperview().offset(-inset)
            } else {
                $0.left.right.equalToSuperview()
            }
        }
    }
    
    func setAttribute(text: NSAttributedString?) {
        contentLabel.attributedText = text;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
