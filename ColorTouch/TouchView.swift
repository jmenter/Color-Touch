
import UIKit

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

class TouchView: UIView {

    private let actualTouches = NSMutableSet()
    private let touchPitchMap = NSMutableDictionary()
    private let toneGenerators:[ToneGenerator]
    private let scale:[CGFloat] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50]
    
    required init?(coder aDecoder: NSCoder) {
        toneGenerators = [ToneGenerator(), ToneGenerator(), ToneGenerator(), ToneGenerator(), ToneGenerator()]
        super.init(coder: aDecoder)
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
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let toneGenerator = touchPitchMap[touch.address()] as! ToneGenerator
            toneGenerator.frequency = quantizedFrequencyForTouch(touch)
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
            let toneGenerator = touchPitchMap[touch.address()] as! ToneGenerator
            toneGenerator.stop()
            touchPitchMap.removeObjectForKey(touch.address())
            actualTouches.removeObject(touch)
        }
        setNeedsDisplay()
    }
    
    // MARK: - Tone/Frequency Utilities
    private func firstAvailableToneGenerator() -> ToneGenerator? {
        for generator in toneGenerators {
            if !(touchPitchMap.allValues as NSArray).containsObject(generator) {
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
        return scale.first! * ((touch.normalizedForce() - 0.1) + 1)
    }
    
    //MARK: - Good ole drawRect
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        for touch in actualTouches {
            let location = touch.locationInView(self)
            let force = 44.0 + (touch.force * 20.0)
            let circle = CGRect(x: location.x - force, y: location.y - force, width: force * 2.0, height: force * 2.0)
            let normalizedForce = touch.force / touch.maximumPossibleForce
            
            CGContextSetFillColorWithColor(context, UIColor(hue: normalizedForce, saturation: normalizedForce, brightness: 1.0, alpha: normalizedForce).CGColor)
            CGContextFillEllipseInRect(context, circle)
            
            CGContextSetLineWidth(context, normalizedForce * 5.0)
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
            CGContextStrokeEllipseInRect(context, circle)
//            NSString(format: "%0.2fhz", 440.0 * ((touch.normalizedForce()) + 1)).drawAtPoint(CGPoint(x: location.x - 12.0, y: location.y - 60.0), withAttributes: nil)
        }
    }

}
