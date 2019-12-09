//
//  SwipsterTextView.swift
//  Swipster
//
//  Created by Daniel Ghrenassia on 20/11/2019.
//  Copyright © 2019 Daniel Ghrenassia. All rights reserved.
//

import UIKit

class SwipsterTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 5)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
    
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }
    
}
