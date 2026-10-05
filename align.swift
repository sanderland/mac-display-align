import AppKit

// Click a point on one display, then the matching point on the neighbouring
// display. Up/Down nudge the first display's line until the two lines meet
// physically, Return moves the second display so both lines share the same
// global y.

struct Mark {
    let display: CGDirectDisplayID
    var x: CGFloat
    var y: CGFloat
}

func cgPoint(_ p: NSPoint) -> CGPoint {
    CGPoint(x: p.x, y: NSScreen.screens[0].frame.height - p.y)
}

func displayID(_ s: NSScreen) -> CGDirectDisplayID {
    s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
}

func align(_ a: Mark, _ b: Mark) {
    let ra = CGDisplayBounds(a.display)
    let rb = CGDisplayBounds(b.display)
    let x = rb.midX >= ra.midX ? ra.maxX : ra.minX - rb.width
    let y = rb.minY + (a.y - b.y)
    var cfg: CGDisplayConfigRef?
    precondition(CGBeginDisplayConfiguration(&cfg) == .success)
    precondition(CGConfigureDisplayOrigin(cfg, b.display, Int32(x), Int32(y)) == .success)
    precondition(CGCompleteDisplayConfiguration(cfg, .permanently) == .success)
}

var first: Mark?
var second: Mark?

final class MarkView: NSView {
    let display: CGDirectDisplayID
    init(frame: NSRect, display: CGDirectDisplayID) {
        self.display = display
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = CGDisplayBounds(display)
        for (mark, color) in [(first, NSColor.systemOrange), (second, NSColor.systemOrange)] {
            guard let m = mark, m.display == display else { continue }
            let y = min(max(m.y - bounds.minY, 0), bounds.height)
            color.setStroke()
            let line = NSBezierPath()
            line.lineWidth = 1
            line.move(to: NSPoint(x: 0, y: y + 0.5))
            line.line(to: NSPoint(x: bounds.width, y: y + 0.5))
            line.stroke()
            color.setFill()
            let x = m.x - bounds.minX
            NSBezierPath(ovalIn: NSRect(x: x - 5, y: y - 4.5, width: 10, height: 10)).fill()
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

var labels: [NSTextField] = []
var views: [MarkView] = []
var windows: [NSWindow] = []
for s in NSScreen.screens {
    let w = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
    w.setFrame(s.frame, display: true)
    w.level = .screenSaver
    w.isOpaque = false
    w.backgroundColor = NSColor.black.withAlphaComponent(0.25)
    let view = MarkView(frame: NSRect(origin: .zero, size: s.frame.size), display: displayID(s))
    w.contentView = view
    let label = NSTextField(labelWithString: "")
    label.font = .systemFont(ofSize: 24, weight: .semibold)
    label.textColor = .white
    label.alignment = .center
    label.frame = NSRect(x: 0, y: 80, width: s.frame.width, height: 36)
    view.addSubview(label)
    labels.append(label)
    views.append(view)
    w.orderFrontRegardless()
    windows.append(w)
}

func setPrompt(_ text: String) {
    for l in labels { l.stringValue = text }
}
func redraw() {
    for v in views { v.needsDisplay = true }
}
setPrompt("Click a point on the edge of one display (Esc to cancel)")

NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .keyDown]) { e in
    if e.type == .keyDown {
        switch e.keyCode {
        case 53:
            exit(0)
        case 126, 125:
            guard first != nil, second != nil else { return nil }
            first!.y += (e.keyCode == 126 ? -1 : 1) * (e.modifierFlags.contains(.shift) ? 10 : 1)
            redraw()
        case 36, 76:
            guard let a = first, let b = second else { return nil }
            align(a, b)
            exit(0)
        default:
            break
        }
        return nil
    }
    guard second == nil else { return nil }
    let screen = windows.first { $0.frame.contains(NSEvent.mouseLocation) }!.screen!
    let p = cgPoint(NSEvent.mouseLocation)
    let mark = Mark(display: displayID(screen), x: p.x, y: p.y)
    if let a = first {
        precondition(a.display != mark.display, "Both clicks were on the same display")
        second = mark
        setPrompt("Up/Down move the line on the first display (Shift = 10 px), Return to lock in, Esc to cancel")
    } else {
        first = mark
        setPrompt("Now click the matching point on the neighbouring display")
    }
    redraw()
    return nil
}
app.run()
