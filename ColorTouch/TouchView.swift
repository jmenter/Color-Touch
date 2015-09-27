
import UIKit

class TouchView: UIView {

    let actualTouches = NSMutableSet()
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        actualTouches.removeAllObjects()
        actualTouches.addObjectsFromArray(Array(touches))
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        actualTouches.addObjectsFromArray(Array(touches))
        setNeedsDisplay()
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            actualTouches.removeObject(touch)
        }
        setNeedsDisplay()
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        for touch in touches! {
            actualTouches.removeObject(touch)
        }
        setNeedsDisplay()

    }
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        for touch in actualTouches {
            let location = touch.locationInView(self)
            let force = 44.0 + (touch.force * 20.0)
            let circle = CGRect(x: location.x - force, y: location.y - force, width: force * 2.0, height: force * 2.0)
            let normalizedForce = touch.force / touch.maximumPossibleForce
            
            CGContextSetFillColorWithColor(context, UIColor(hue: normalizedForce, saturation: normalizedForce, brightness: 1.0, alpha: normalizedForce).CGColor)
            CGContextFillEllipseInRect(context, circle)
            
            CGContextSetLineWidth(context, normalizedForce * 5)
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
            CGContextStrokeEllipseInRect(context, circle)
        }
    }

}
