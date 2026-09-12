import AppKit
import CoreGraphics
import Foundation

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "sample.pdf"
let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

let info: [CFString: Any] = [
    kCGPDFContextTitle: "Quarterly Report (Demo)",
    kCGPDFContextAuthor: "Demo User",
    kCGPDFContextCreator: "MetaPeek Demo Generator",
]

guard let ctx = CGContext(URL(fileURLWithPath: outputPath) as CFURL, mediaBox: nil, info as CFDictionary) else {
    fatalError("could not create PDF context")
}

ctx.beginPDFPage(nil)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

let title = "Confidential Project Report"
let body = """
This is a placeholder document generated purely to demonstrate
MetaPeek's metadata inspection features. It contains no real data.

Section 1: Overview
Section 2: Findings
Section 3: Recommendations
"""

let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 22),
    .foregroundColor: NSColor.black,
]
NSAttributedString(string: title, attributes: titleAttrs).draw(at: CGPoint(x: 60, y: pageRect.height - 100))

let bodyAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13),
    .foregroundColor: NSColor.darkGray,
]
NSAttributedString(string: body, attributes: bodyAttrs).draw(in: CGRect(x: 60, y: pageRect.height - 320, width: pageRect.width - 120, height: 220))

NSGraphicsContext.restoreGraphicsState()
ctx.endPDFPage()
ctx.closePDF()

print("wrote \(outputPath)")
