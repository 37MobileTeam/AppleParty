//
//  DropZoneView.swift
//  SymbolicatorX
//
//  Created by 钟晓跃 on 2020/7/6.
//  Copyright © 2020 钟晓跃. All rights reserved.
//

import Cocoa
import SnapKit

protocol DropZoneViewDelegate: AnyObject {
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL)
    func receivedMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent)
    func receivedRightMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent)
}

// @optional
extension DropZoneViewDelegate {
    func receivedMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent) {}
    func receivedRightMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent) {}
}

class DropZoneView: NSView {
    
    private let containerView = NSView()
    private let iconImageView = NSImageView()
    private let fileTypeTextField = NSTextField()
    private let textTextField = NSTextField()
    private let detailTextTextField = NSTextField()
    
    weak var delegate: DropZoneViewDelegate?
    private var isHoveringFile = false
    private var fileTypes = [String]()
    private var file: URL?
    
    private var defaultText: String?
    private var defaultDetailText: String?
        
    var fileTypesPredicate: NSPredicate {
        let predicateFormat = (0..<fileTypes.count).map { (index) -> String in
            return "SELF ENDSWITH[c] %@"
        }.joined(separator: " OR ")
        return NSPredicate(format: predicateFormat, argumentArray: fileTypes)
    }
    
    init(fileTypes: [String], text: String? = nil, detailText: String? = nil) {
        super.init(frame: .zero)
        defaultText = text
        defaultDetailText = detailText
        setFileTypes(fileTypes)
        setText(text)
        setDetailText(detailText)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reset() {
        setFile(nil)
        setDetailText(nil)
        setText(defaultText)
        setDetailText(defaultDetailText)
    }
    
    public func setHoveringFile(_ isHoveringFile: Bool) {
        
        self.isHoveringFile = isHoveringFile
        display()
    }
    
    public func setIcon(_ icon: NSImage?) {
        
        icon?.size = NSSize(width: 64, height: 64)
        iconImageView.image = icon
        iconImageView.sizeToFit()
    }
    
    public func setFile(_ file: URL?) {
        
        guard file != self.file else { return }
        self.file = file
        setText(file?.lastPathComponent)
        display()
    }
    
    public func setText(_ text: String?) {
        
        guard let newText = text else {
            textTextField.stringValue = ""
            return
        }

        textTextField.attributedStringValue = NSAttributedString(string: newText, attributes: Style.textAttributes(size: 14, color: .secondaryLabelColor))
    }
    
    public func setDetailText(_ detailText: String?) {
        
        guard let newDetailText = detailText else {
            detailTextTextField.stringValue = ""
            return
        }

        detailTextTextField.attributedStringValue = NSAttributedString(string: newDetailText, attributes: Style.textAttributes(size: 12, color: .tertiaryLabelColor))
    }
    
    public func setFileTypes(_ fileTypes: [String]) {
        
//        guard !fileTypes.isEmpty else {
//            setIcon(nil)
//            fileTypeTextField.attributedStringValue = NSAttributedString()
//            unregisterDraggedTypes()
//            return
//        }
        
        self.fileTypes = fileTypes.map({ (fileType) -> String in
            return (fileType.hasPrefix(".") ? "" : ".").appending(fileType.lowercased())
        })
        
        registerForDraggedTypes([(kUTTypeFileURL as
        NSPasteboard.PasteboardType)])
        
        let primaryFileType = self.fileTypes.isEmpty ? "" : fileTypes[0]
        setIcon(NSWorkspace.shared.icon(forFileType: primaryFileType))
        fileTypeTextField.attributedStringValue = NSAttributedString(string: primaryFileType, attributes: Style.textAttributes(size: 16, color: .labelColor))
    }
    
    public func acceptFile(url fileURL: URL) -> Bool {
        
        guard validFileURL(fileURL) else { return false }

        setFile(fileURL)
        delegate?.receivedFile(dropZoneView: self, fileURL: fileURL)

        return true
    }
}

// MARK: - NSDraggingDestination
extension DropZoneView {
    override func mouseDown(with theEvent: NSEvent) {
        delegate?.receivedMouseDown(dropZoneView: self, theEvent: theEvent)
    }

    override func rightMouseDown(with theEvent: NSEvent) {
        delegate?.receivedRightMouseDown(dropZoneView: self, theEvent: theEvent)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        
        let isHoveringFile = (validDraggedFileURL(from: sender) != nil)
        setHoveringFile(isHoveringFile)
        return isHoveringFile ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {

        setHoveringFile(false)
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        defer { setHoveringFile(false) }
        
        guard let draggedFileURL = validDraggedFileURL(from: sender) else { return false }
        
        setFile(draggedFileURL)
        delegate?.receivedFile(dropZoneView: self, fileURL: draggedFileURL)

        return true
    }

    private func validDraggedFileURL(from draggingInfo: NSDraggingInfo) -> URL? {
        
        guard
            let draggedFile = draggingInfo.draggingPasteboard.string(forType: kUTTypeFileURL as NSPasteboard.PasteboardType),
            let draggedFileURL = URL(string: draggedFile)
        else {
            return nil
        }

        return validFileURL(draggedFileURL) ? draggedFileURL : nil
    }

    private func validFileURL(_ url: URL) -> Bool {
        if fileTypes.isEmpty {
            let fm = FileManager.default
            var isDirectory: ObjCBool = false
            // 不允许是目录
            if (fm.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
               return false
            }
            return true
        }
        return fileTypesPredicate.evaluate(with: url.path)
    }
}

// MARK: - Helpers
extension DropZoneView {
    
    private struct Colors {
        static let gray1 = NSColor(calibratedWhite: 0.7, alpha: 1)
        static let gray2 = NSColor(calibratedWhite: 0.4, alpha: 1)
        static let shade = NSColor(calibratedWhite: 0.0, alpha: 0.025)
    }

    private struct Style {
        
        static func textAttributes(size: CGFloat, color: NSColor) -> [NSAttributedString.Key: Any] {
            
            let centeredTextStyle = (NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle)
            centeredTextStyle.alignment = .center
            
            return [
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: size),
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.paragraphStyle: centeredTextStyle
            ]
        }
    }
}

// MARK: - UI
extension DropZoneView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        (isHoveringFile ? Colors.shade : NSColor.clear).setFill()
        dirtyRect.fill()

        let borderPadding: CGFloat = 6
        let drawRect = dirtyRect.insetBy(dx: borderPadding, dy: borderPadding)

        let alpha: CGFloat = file == nil ? 1 : 0.2
        let dashed = file == nil
        
        (isHoveringFile ? Colors.gray2 : Colors.gray1).withAlphaComponent(alpha).setStroke()

        let roundedRectanglePath = NSBezierPath(roundedRect: drawRect, xRadius: 8, yRadius: 8)
        roundedRectanglePath.lineWidth = 1.5
        if dashed {
            roundedRectanglePath.setLineDash([6, 6, 6, 6], count: 4, phase: 0)
        }
        roundedRectanglePath.stroke()
    }
    
    private func setupUI() {
        
        wantsLayer = true
        layer?.cornerRadius = 14
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.equalTo(self).offset(-40)
        }
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.unregisterDraggedTypes()
        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(64)
        }
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        fileTypeTextField.drawsBackground = false
        fileTypeTextField.isBezeled = false
        fileTypeTextField.isEditable = false
        fileTypeTextField.isSelectable = false
        containerView.addSubview(fileTypeTextField)
        fileTypeTextField.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
            make.height.lessThanOrEqualTo(26)
        }
        
        textTextField.translatesAutoresizingMaskIntoConstraints = false
        textTextField.drawsBackground = false
        textTextField.isBezeled = false
        textTextField.isEditable = false
        textTextField.isSelectable = false
        textTextField.cell?.lineBreakMode = .byTruncatingMiddle
        containerView.addSubview(textTextField)
        textTextField.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(fileTypeTextField.snp.bottom).offset(12)
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.lessThanOrEqualTo(70)
        }
        
        detailTextTextField.translatesAutoresizingMaskIntoConstraints = false
        detailTextTextField.drawsBackground = false
        detailTextTextField.isBezeled = false
        detailTextTextField.isEditable = false
        detailTextTextField.isSelectable = false
        detailTextTextField.cell?.truncatesLastVisibleLine = true
        containerView.addSubview(detailTextTextField)
        detailTextTextField.snp.makeConstraints { (make) in
            make.centerX.bottom.equalToSuperview()
            make.top.equalTo(textTextField.snp.bottom)
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.lessThanOrEqualTo(70)
        }
    }
}
