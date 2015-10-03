
import UIKit
import SpriteKit

extension SKEmitterNode {
    
    class func createSparkEmitterNode() -> SKEmitterNode {
        let sparkEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("Spark", ofType: "sks")!) as! SKEmitterNode
        sparkEmitter.particleBirthRate = 0
        return sparkEmitter
    }
    
}

class TouchView: UIView {

    private let actualTouches = NSMutableSet()
    private let touchPitchMap = NSMutableDictionary()
    private let toneGenerators:[ToneGenerator] = [ToneGenerator(), ToneGenerator(), ToneGenerator(), ToneGenerator(), ToneGenerator()]
    private let touchSparkMap = NSMutableDictionary()
    private let sparkGenerators:[SKEmitterNode] = [SKEmitterNode.createSparkEmitterNode(), SKEmitterNode.createSparkEmitterNode(), SKEmitterNode.createSparkEmitterNode(), SKEmitterNode.createSparkEmitterNode(), SKEmitterNode.createSparkEmitterNode()]
    private let scale:[CGFloat] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50]
    private let notes:[CGFloat:String] = [523.25:"C", 587.33:"D", 659.25:"E", 698.46:"F", 783.99:"G", 880.00:"A", 987.77:"B", 1046.50:"C"]
    private let textAttributes = [NSFontAttributeName:UIFont.boldSystemFontOfSize(72), NSForegroundColorAttributeName:UIColor.whiteColor()]
    private let skView = SKView()
    private let scene = SKScene(size: CGSizeMake(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(skView)
        skView.backgroundColor = UIColor.clearColor()
        if true {
            skView.showsDrawCount = true
            skView.showsNodeCount = true
            skView.showsFPS = true
            skView.showsQuadCount = true
        }
        skView.userInteractionEnabled = false
        
        for node in sparkGenerators {
            scene.addChild(node)
        }
        
        scene.backgroundColor = SKColor.clearColor()
        skView.presentScene(scene)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        skView.frame = bounds
        scene.size = bounds.size
    }
    
    // MARK: - UITouch Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            actualTouches.addObject(touch)
            let toneGenerator = firstAvailableToneGenerator()
            touchPitchMap[touch.address()] = toneGenerator
            toneGenerator?.frequency
            toneGenerator?.frequency = quantizedFrequencyForTouch(touch)
            toneGenerator?.play()
            let sparkGenerator = firstAvailableSparkGenerator()
            touchSparkMap[touch.address()] = sparkGenerator
            sparkGenerator?.particleBirthRate = touch.force * 500.0
            sparkGenerator?.particleColor = UIColor(hue: quantizedFrequencyForTouch(touch) / scale.last!, saturation: 0.75, brightness: 1.0, alpha: 1.0)
            sparkGenerator?.particlePosition = CGPoint(x: touch.locationInView(self).x, y: bounds.size.height - touch.locationInView(self).y)
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if let toneGenerator = toneGeneratorForTouch(touch) {
                toneGenerator.frequency = quantizedFrequencyForTouch(touch)
            }
            if let sparkGenerator = sparkGeneratorForTouch(touch) {
                sparkGenerator.particleBirthRate = touch.force * 500.0
                sparkGenerator.particleColor = UIColor(hue: quantizedFrequencyForTouch(touch) / scale.last!, saturation: 0.75, brightness: 1.0, alpha: 1.0)
                sparkGenerator.particlePosition = CGPoint(x: touch.locationInView(self).x, y: bounds.size.height - touch.locationInView(self).y)
            }
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        finishTouches(touches)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        finishTouches(touches)
    }
    
    private func finishTouches(touches: Set<UITouch>?) {
        for touch in touches! {
            if let sparkGenerator = sparkGeneratorForTouch(touch) {
                sparkGenerator.particleBirthRate = 0.0
                touchSparkMap.removeObjectForKey(touch.address())
            }

            if let toneGenerator = toneGeneratorForTouch(touch) {
                toneGenerator.stop()
                touchPitchMap.removeObjectForKey(touch.address())
                actualTouches.removeObject(touch)
            }
        }
        setNeedsDisplay()
    }
    
    // MARK: - Tone/Frequency Utilities
    private func toneGeneratorForTouch(touch:UITouch) -> ToneGenerator? {
        if let toneGenerator = touchPitchMap[touch.address()] as? ToneGenerator {
            return toneGenerator
        }
        return nil
    }
    
    private func sparkGeneratorForTouch(touch:UITouch) -> SKEmitterNode? {
        if let sparkGenerator = touchSparkMap[touch.address()] as? SKEmitterNode {
            return sparkGenerator
        }
        return nil
    }
    
    private func firstAvailableToneGenerator() -> ToneGenerator? {
        for generator in toneGenerators {
            if !(touchPitchMap.allValues as NSArray).containsObject(generator) {
                return generator
            }
        }
        return nil
    }
    
    private func firstAvailableSparkGenerator() -> SKEmitterNode? {
        for generator in sparkGenerators {
            if !(touchSparkMap.allValues as NSArray).containsObject(generator) {
                return generator
            }
        }
        return nil
    }
    
    private func quantizedFrequencyForTouch(touch:UITouch) -> CGFloat {
        let rawFrequency = frequencyForTouch(touch)
        var quantizedFrequency = rawFrequency
        for frequency in scale {
            if rawFrequency < frequency {
                quantizedFrequency = frequency
                break
            }
        }
        return quantizedFrequency
    }
    
    private func frequencyForTouch(touch:UITouch) -> CGFloat {
        return scale.first! * ((touch.normalizedForce() - 0.1) + 1.0)
    }
    
    //MARK: - Good ole drawRect
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        for touch in actualTouches {
            let location = touch.locationInView(self)
            let force = 44.0 + (touch.force * 20.0)
            let circle = CGRect(x: location.x - force, y: location.y - force, width: force * 2.0, height: force * 2.0)
//            let normalizedForce = touch.force / touch.maximumPossibleForce
            let normalizedForce = quantizedFrequencyForTouch(touch as! UITouch) / scale.last!

            CGContextSetFillColorWithColor(context, UIColor(hue: normalizedForce, saturation: 0.75, brightness: 0.5, alpha: 1.0).CGColor)
            CGContextFillEllipseInRect(context, circle)
            
//            CGContextSetLineWidth(context, normalizedForce * 5.0)
//            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
//            CGContextStrokeEllipseInRect(context, circle)
            
            notes[quantizedFrequencyForTouch(touch as! UITouch)]!.drawAtPoint(CGPoint(x: location.x - 20.0, y: location.y - 120.0), withAttributes: textAttributes)
        }
    }

}

//MARK: - Some Nifty Extensions
extension NSObject {
    
    func address() -> NSString {
        return NSString(format: "%p", unsafeAddressOf(self))
    }
}

extension UITouch {
    func normalizedForce() -> CGFloat {
        return force / maximumPossibleForce
    }
}
