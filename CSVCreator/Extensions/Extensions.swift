//
//  Extensions.swift
//  CSVCreator
//
//  Created by Cole M on 12/27/21.
//  Copyright © 2021 Cole M. All rights reserved.
//

import Cocoa


extension NSTextField {
    
    /// Return an `NSTextField` configured exactly like one created by dragging a “Label” into a storyboard.
    class func newLabel() -> NSTextField {
        let label = NSTextField()
        label.wantsLayer = true
        label.isEditable = false
        label.isSelectable = false
        label.backgroundColor = .clear
        label.isBordered = false
        label.textColor = .white
        label.drawsBackground = false
        label.isBezeled = false
        label.alignment = .natural
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: label.controlSize))
        //        label.lineBreakMode = .byClipping
        label.cell?.isScrollable = true
        label.cell?.wraps = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}


extension NSStackView {
    
    func removeFully(view: NSView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
    
    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }
    
}

extension Collection {
    
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
    
}

extension NSButton {
    open override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}


extension NSAlert {
    func configuredAlert(title: String, text: String, singleButton: Bool = false, switchRun: Bool = false)  {
        self.messageText = title
        self.informativeText = text
        self.alertStyle = NSAlert.Style.warning
        self.addButton(withTitle: "OK")
        if !singleButton {
        self.addButton(withTitle: "Cancel")
        }
        if !switchRun {
        self.runModal()
        }
    }
    
    func configuredCustomButtonAlert(title: String, text: String, firstButtonTitle: String, singleButton: Bool = false, secondButtonTitle: String, switchRun: Bool = false)  {
        self.messageText = title
        self.informativeText = text
        self.alertStyle = NSAlert.Style.warning
        self.addButton(withTitle: firstButtonTitle)
        if !singleButton {
        self.addButton(withTitle: secondButtonTitle)
        }
        if !switchRun {
        self.runModal()
        }
    }
}
