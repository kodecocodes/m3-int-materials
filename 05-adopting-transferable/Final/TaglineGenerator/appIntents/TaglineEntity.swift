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

// MARK: - Transferable
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
    // Force-try for brevity; use `try` with proper error handling in production
    return try! encoder.encode(tagline.tagline)
  }
}

private enum TaglineShareText {
  static func textData(for tagline: TaglineEntity) -> Data {
    let titleString = String(describing: tagline.displayRepresentation.title)
    let subtitleString = String(
      describing: tagline.displayRepresentation.subtitle
    )
    return Data("\(titleString) - \(subtitleString)".utf8)
  }
}
