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

import AppIntents
import CoreTransferable
import Foundation
import FoundationModels
import UIKit
import UniformTypeIdentifiers

private typealias PlatformColor = UIColor
private typealias PlatformFont = UIFont

struct Tagline: Identifiable, Hashable, Sendable, Codable {
  var id: String
  var originalTagline: String
  var enhancedTagline: String
  var model: String
  var temperature: Double
}

@AppEntity(schema: .notes.note)
struct TaglineEntity: AppEntity, IndexedEntity {
  static let defaultQuery = TaglineEntityQuery()

  let id: Tagline.ID

  @Property(title: "Original tagline")
  var originalTagline: String

  @Property(title: "Enhanced Tagline")
  var enhancedTagline: String

  @Property(title: "Model name")
  var modelName: String

  @Property(title: "Temperature")
  var temperature: Double

  var attachments: [IntentFile]
  var content: AttributedString?
  var creationDate: Date?
  var folder: FolderEntity?
  var isPinned: Bool
  var modificationDate: Date?
  var name: AttributedString

  var tagline: Tagline

  init(tagline: Tagline) {
    self.id = tagline.id
    self.tagline = tagline
    self.originalTagline = tagline.originalTagline
    self.enhancedTagline = tagline.enhancedTagline
    self.modelName = tagline.model
    self.temperature = tagline.temperature
    self.name = AttributedString(stringLiteral: tagline.originalTagline)
    self.content = AttributedString(stringLiteral: tagline.enhancedTagline)
    self.attachments = []
    self.isPinned = false
    self.creationDate = Date()
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(originalTagline) became \(enhancedTagline)",
      subtitle: "Model: \(modelName), Temperature: \(temperature)"
    )
  }

  struct TaglineEntityQuery: EntityStringQuery {
    @Dependency var taglineManager: TaglineDataManager

    func entities(for identifiers: [TaglineEntity.ID]) async throws
      -> [TaglineEntity] {
      return taglineManager.taglines(with: identifiers)
        .map { TaglineEntity(tagline: $0) }
    }

    func entities(matching identifier: String) async throws -> [TaglineEntity] {
      return
        taglineManager
        .taglines { tagline in
          tagline.originalTagline.localizedCaseInsensitiveContains(identifier)
        }
        .map { TaglineEntity(tagline: $0) }
    }
  }
}

@AppEntity(schema: .notes.folder)
struct FolderEntity {
  // MARK: Static

  static let defaultQuery = FolderEntityQuery()

  // MARK: Properties

  let id: String

  var name: String
  var parentFolder: FolderEntity?
  var account: AccountEntity?

  init(
    id: String,
    name: String,
    parentFolder: FolderEntity?,
    account: AccountEntity?
  ) {
    self.id = id
    self.name = name
    self.parentFolder = parentFolder
    self.account = account
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
  }

  // MARK: Query

  struct FolderEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [FolderEntity] {
      identifiers.map {
        FolderEntity(id: $0, name: $0, parentFolder: nil, account: nil)
      }
    }

    func entities(matching string: String) async throws -> [FolderEntity] {
      [FolderEntity(id: string, name: string, parentFolder: nil, account: nil)]
    }
  }
}

@AppEntity(schema: .notes.account)
struct AccountEntity {
  // MARK: Static

  static let defaultQuery = AccountEntityQuery()

  // MARK: Properties

  let id: String

  @Property var name: String

  init(id: String, name: String) {
    self.id = id
    self.name = name
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
  }

  // MARK: Query

  struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AccountEntity] {
      identifiers.map { AccountEntity(id: $0, name: $0) }
    }
  }
}

extension TaglineEntity: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .text) { tagline in
      TaglineShareText.textData(for: tagline)
    }
    DataRepresentation(exportedContentType: .json) { tagline in
      TaglineShareJson.jsonData(for: tagline)
    }
    DataRepresentation(exportedContentType: .png) { tagline in
      TaglineShareImageRenderer.pngData(for: tagline)
    }
  }
}

private enum TaglineShareJson {
  static func jsonData(for tagline: TaglineEntity) -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try! encoder.encode(tagline.tagline)
  }
}

private enum TaglineShareText {
  static func textData(for tagline: TaglineEntity) -> Data {
    let titleString = String(describing: tagline.displayRepresentation.title)
    let subtitleString = String(
      describing: tagline.displayRepresentation.subtitle
    )
    return "\(titleString) - \(subtitleString)".data(using: .utf8) ?? Data()
  }
}

private enum TaglineShareImageRenderer {
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
        PlatformColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
        PlatformColor(red: 0.22, green: 0.13, blue: 0.30, alpha: 1.0).cgColor,
        PlatformColor(red: 0.08, green: 0.19, blue: 0.22, alpha: 1.0).cgColor
      ] as CFArray
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    guard
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: locations
      )
    else {
      context.setFillColor(PlatformColor.black.cgColor)
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
      color: PlatformColor.black.withAlphaComponent(0.35).cgColor
    )
    PlatformColor(white: 1.0, alpha: 0.10).setFill()
    context.addPath(cardPath)
    context.fillPath()
    context.restoreGState()

    PlatformColor(white: 1.0, alpha: 0.16).setStroke()
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
      color: PlatformColor.white.withAlphaComponent(0.72),
      alignment: .left
    )

    drawLabeledBlock(
      label: "Source",
      text: String(tagline.name.characters),
      in: sourceBlock,
      context: context,
      fillColor: PlatformColor.white.withAlphaComponent(0.08)
    )

    let enhanced = tagline.content.map { String($0.characters) } ?? ""
    drawLabeledBlock(
      label: "Enhanced",
      text: enhanced,
      in: enhancedBlock,
      context: context,
      fillColor: PlatformColor(red: 0.98, green: 0.55, blue: 0.18, alpha: 0.16)
    )

    draw(
      text: "Shared from Tagline Generator",
      in: footerFrame,
      font: systemFont(size: 16, weight: .medium),
      color: PlatformColor.white.withAlphaComponent(0.55),
      alignment: .left
    )
  }

  private static func drawLabeledBlock(
    label: String,
    text: String,
    in frame: CGRect,
    context: CGContext,
    fillColor: PlatformColor
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
      color: PlatformColor.white.withAlphaComponent(0.72),
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
    font: PlatformFont,
    color: PlatformColor,
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
