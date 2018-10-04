//
//  VTCircle.swift
//  Pods-VTCircle_Example
//
//  Created by Vu Dinh Vinh on 10/4/18.
//

import UIKit

let timeToStop = .pi as double_t

@objc protocol VTCircleViewDelegate: NSObjectProtocol {
    @objc optional func setStop()
}

@IBDesignable
class VTCircle: UIView {
    private var lastDuration: Float = 0
    private var currentSpeed: Float = 0
    private var numberOfSectors: Int = 8
    private var inertiaTimer: Timer?
    private var currentIndex: Int = 0
    private var animationDecelerationFactor: Float = 1
    private var timeRemaining: Int = 0
    private var remainingCount: Int = 0
    private var card: Int = 0
    private var remainingTimer: Timer?
    
    @IBInspectable var circleImage: UIImage = UIImage() {
        didSet {
            wheelImage.image = circleImage
        }
    }
    
    @IBInspectable var pointerImage: UIImage = UIImage() {
        didSet {
            pointerButton.setBackgroundImage(pointerImage, for: .normal)
        }
    }
    
    var currentRotation: Float = 0.0
    weak var delegate: (UIViewController & VTCircleViewDelegate)?
    var stopIndex: Int = 0
    
    let pointerButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.layer.cornerRadius = 50
        button.setTitle("START", for: .normal)
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(touchStart), for: .touchUpInside)
        return button
    }()
    
    let wheelImage: UIImageView = {
        let image = UIImageView(frame: .zero)
        image.backgroundColor = .clear
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberOfSectors = 8
        stopIndex = -1
        currentIndex = -1
        animationDecelerationFactor = 1
        wheelImage.transform = CGAffineTransform(rotationAngle: 0)
        
        pointerButton.layer.cornerRadius = pointerButton.frame.size.width / 2
    }
    
    func setupView() {
        addSubview(wheelImage)
        addSubview(pointerButton)
        wheelImage.frame = frame
        pointerButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        addConstraint(NSLayoutConstraint(item: pointerButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: pointerButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: wheelImage, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: wheelImage, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: wheelImage, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: wheelImage, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
    }
    
    //MARK: wheel
    func rotateToCurrentRotation(animated: Bool) {
        let animationBlock: () -> () = {
            self.wheelImage.transform = CGAffineTransform(rotationAngle: CGFloat(self.currentRotation))
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                animationBlock()
            }) { finished in
                
            }
        } else {
            animationBlock()
        }
    }

    func continueRotationAnimated(_ rotate: Float, animated: Bool, withDuration duration: Float) {
        let animationBlock: () -> () = {
            self.wheelImage.transform = CGAffineTransform(rotationAngle: CGFloat(self.currentRotation + rotate))
        }
        
        if animated {
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                animationBlock()
            }) { finished in
                
            }
        } else {
            animationBlock()
        }
    }
    
    @objc func onInertiaTimer() {
        currentRotation += currentSpeed
        currentIndex = rotation2index(currentRotation)
        rotateToCurrentRotation(animated: true)
        if currentSpeed >= Float(0.01) {
            currentSpeed *= animationDecelerationFactor
            if currentIndex == stopIndex {
                animationDecelerationFactor = 1 - 1 / (4 * .pi)
            }
        } else if currentSpeed < Float(0.01) {
            if currentIndex != stopIndex {
                return
            } else {
                currentRotation += currentSpeed
                rotateToCurrentRotation(animated: true)
                stopInertiaTimer()
            }
        }
    }

    func continueByInertia() {
        if (inertiaTimer != nil) {
            return
        }
        currentSpeed = 1
        if (delegate != nil) && (delegate?.responds(to: #selector(self.setStop)))! {
            delegate?.perform(#selector(self.setStop), with: nil, afterDelay: 3)
        } else {
            setStop()
        }
        
        inertiaTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.onInertiaTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(inertiaTimer!, forMode: RunLoop.Mode.init("common"))
        onInertiaTimer() // excute once immediately
        
    }

    func stopInertiaTimer() {
        if (inertiaTimer != nil) {
            inertiaTimer!.invalidate()
            inertiaTimer = nil
            stopIndex = -1
            animationDecelerationFactor = 1
        }
    }

    @objc func touchStart() {
        continueByInertia()
    }
    
    @objc func setStop() {
        let randomNumber = Int(arc4random()) % 8
        stopIndex = randomNumber
        print(String(format: "%i", stopIndex))
    }
    
    func index2rotation(_ index: Int) -> Float {
        let r: Float = 0 - (.pi * 2 / Float(numberOfSectors)) * Float(index)
        return r
    }
    
    func rotation2index(_ rotation: Float) -> Int {
        let rotation2: Float = rotation + (.pi * 2 / Float(numberOfSectors)) / 2
        
        var index = (Int(floorf((rotation2 - 0) / (.pi * 2 / Float(numberOfSectors))))) % numberOfSectors
        if index > 0 {
            index = numberOfSectors - index
        } else if index < 0 {
            index = -index
        }
        return index
    }
}
