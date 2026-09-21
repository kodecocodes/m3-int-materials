/// Copyright (c) 2026 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import UIKit
import UniformTypeIdentifiers

enum TaglineShareImageRenderer {
  static func pngData(for tagline: TaglineEntity) -> Data {
    let renderer = UIGraphicsImageRenderer(size: canvasSize)
    let image = renderer.image { context in
      draw(tagline: tagline, in: context.cgContext)
    }
    return image.pngData() ?? Data()
  }

  private static let canvasSize = CGSize(width: 1200, height: 675)

  private static func draw(tagline: TaglineEntity, in context: CGContext) {
    let bounds = CGRect(origin: .zero, size: canvasSize)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    drawGradient(in: context, bounds: bounds)
    drawCardChrome(in: context, bounds: bounds)
    drawContent(tagline: tagline, in: context, bounds: bounds)
  }

  private static func drawGradient(in context: CGContext, bounds: CGRect) {
    let colors =
      [
        UIColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
        UIColor(red: 0.22, green: 0.13, blue: 0.30, alpha: 1.0).cgColor,
        UIColor(red: 0.08, green: 0.19, blue: 0.22, alpha: 1.0).cgColor
      ] as CFArray
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    guard
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: locations
      )
    else {
      context.setFillColor(UIColor.black.cgColor)
      context.fill(bounds)
      return
    }

    context.drawLinearGradient(
      gradient,
      start: CGPoint(x: bounds.minX, y: bounds.minY),
      end: CGPoint(x: bounds.maxX, y: bounds.maxY),
      options: []
    )
  }

  private static func drawCardChrome(in context: CGContext, bounds: CGRect) {
    let insetBounds = bounds.insetBy(dx: 64, dy: 54)
    let cardPath = CGPath(
      roundedRect: insetBounds,
      cornerWidth: 42,
      cornerHeight: 42,
      transform: nil
    )

    context.saveGState()
    context.setShadow(
      offset: CGSize(width: 0, height: 30),
      blur: 40,
      color: UIColor.black.withAlphaComponent(0.35).cgColor
    )
    UIColor(white: 1.0, alpha: 0.10).setFill()
    context.addPath(cardPath)
    context.fillPath()
    context.restoreGState()

    UIColor(white: 1.0, alpha: 0.16).setStroke()
    context.setLineWidth(1)
    context.addPath(cardPath)
    context.strokePath()
  }

  private static func drawContent(
    tagline: TaglineEntity,
    in context: CGContext,
    bounds: CGRect
  ) {
    let insetBounds = bounds.insetBy(dx: 84, dy: 74)
    let titleFrame = CGRect(
      x: insetBounds.minX,
      y: insetBounds.minY,
      width: insetBounds.width,
      height: 70
    )
    let subtitleFrame = CGRect(
      x: insetBounds.minX,
      y: titleFrame.maxY + 4,
      width: insetBounds.width,
      height: 34
    )
    let sourceBlock = CGRect(
      x: insetBounds.minX,
      y: subtitleFrame.maxY + 30,
      width: insetBounds.width,
      height: 170
    )
    let enhancedBlock = CGRect(
      x: insetBounds.minX,
      y: sourceBlock.maxY + 28,
      width: insetBounds.width,
      height: 200
    )
    let footerFrame = CGRect(
      x: insetBounds.minX,
      y: bounds.maxY - 118,
      width: insetBounds.width,
      height: 26
    )

    draw(
      text: "Tagline Generator",
      in: titleFrame,
      font: systemFont(size: 34, weight: .bold),
      color: .white,
      alignment: .left
    )
    draw(
      text: "Source and enhanced tagline",
      in: subtitleFrame,
      font: systemFont(size: 18, weight: .semibold),
      color: UIColor.white.withAlphaComponent(0.72),
      alignment: .left
    )

    drawLabeledBlock(
      label: "Source",
      text: String(tagline.name.characters),
      in: sourceBlock,
      context: context,
      fillColor: UIColor.white.withAlphaComponent(0.08)
    )

    let enhanced = tagline.content.map { String($0.characters) } ?? ""
    drawLabeledBlock(
      label: "Enhanced",
      text: enhanced,
      in: enhancedBlock,
      context: context,
      fillColor: UIColor(red: 0.98, green: 0.55, blue: 0.18, alpha: 0.16)
    )

    draw(
      text: "Shared from Tagline Generator",
      in: footerFrame,
      font: systemFont(size: 16, weight: .medium),
      color: UIColor.white.withAlphaComponent(0.55),
      alignment: .left
    )
  }

  private static func drawLabeledBlock(
    label: String,
    text: String,
    in frame: CGRect,
    context: CGContext,
    fillColor: UIColor
  ) {
    let path = CGPath(
      roundedRect: frame,
      cornerWidth: 28,
      cornerHeight: 28,
      transform: nil
    )
    context.saveGState()
    fillColor.setFill()
    context.addPath(path)
    context.fillPath()
    context.restoreGState()

    let labelFrame = CGRect(
      x: frame.minX + 24,
      y: frame.minY + 18,
      width: frame.width - 48,
      height: 28
    )
    draw(
      text: label.uppercased(),
      in: labelFrame,
      font: systemFont(size: 16, weight: .bold),
      color: UIColor.white.withAlphaComponent(0.72),
      alignment: .left
    )

    let textFrame = CGRect(
      x: frame.minX + 24,
      y: frame.minY + 50,
      width: frame.width - 48,
      height: frame.height - 66
    )
    draw(
      text: text,
      in: textFrame,
      font: systemFont(size: 30, weight: .semibold),
      color: .white,
      alignment: .left
    )
  }

  private static func draw(
    text: String,
    in frame: CGRect,
    font: UIFont,
    color: UIColor,
    alignment: NSTextAlignment
  ) {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: paragraphStyle
    ]

    (text as NSString).draw(in: frame, withAttributes: attributes)
  }

  private static func systemFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
    UIFont.systemFont(ofSize: size, weight: weight)
  }
}
