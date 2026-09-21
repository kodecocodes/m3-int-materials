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
import FoundationModels

enum TaglineEnhancer {
  static func generate(from sourceTagline: String) async throws -> String {
    let model = SystemLanguageModel.default

    guard model.availability == .available else {
      return fallbackEnhancement(for: sourceTagline)
    }

    let session = LanguageModelSession()
    let response = try await session.respond(
      to: """
        Rewrite this tagline into a single over-the-top marketing line packed
        with buzzwords, momentum, and confidence. Keep the core meaning intact. Tagline: \(sourceTagline)
        """,
      generating: EnhancedTagline.self
    )

    let value = response.content.text.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    return value.isEmpty ? fallbackEnhancement(for: sourceTagline) : value
  }

  static func fallbackEnhancement(for sourceTagline: String) -> String {
    let leadIns = [
      "Next-level", "Category-defining", "Hypercharged", "Turbocharged",
      "Future-ready"
    ]
    let modifiers = [
      "synergy", "velocity", "innovation", "excellence", "momentum"
    ]
    let ending = [
      "for unstoppable results.", "for maximum impact.",
      "that overdelivers at scale.", "engineered to dominate."
    ]

    let lead = leadIns[sourceTagline.count % leadIns.count]
    let modifier = modifiers[sourceTagline.count % modifiers.count]
    let suffix = ending[sourceTagline.count % ending.count]
    return "\(lead) \(sourceTagline) with \(modifier) \(suffix)"
  }
}

@Generable
private struct EnhancedTagline {
  @Guide(
    description: "A single over-the-top, buzzword-heavy marketing tagline."
  )
  var text: String
}
