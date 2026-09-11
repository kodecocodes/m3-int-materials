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

enum CreativityLevel: Int, CaseIterable {
  case low, medium, high
}

struct CreativityInstructions: DynamicInstructions {
  var creativityLevel: CreativityLevel = .low

  var body: some DynamicInstructions {
    // add instructions to guide the model; these act with any instance of this DynamicInstruction
    Instructions {
      if creativityLevel == .low {
        "You are an novice marketer, and your taglines are often a bit clichéd."
      } else if creativityLevel == .medium {
        "You are a mid career marketer, and your taglines are a bit more original, but still not as innovative as you'd like"
      } else {
        "You are an experienced marketer, and draw upon years of experience to generate the best taglines possible"
      }
    }

    // if we wanted to specify tools, we could do that here

    // we could also add additional instructions for CreativityLevels other than "low"; for this example, we don't need much else
    if creativityLevel == .medium {
      // put additional DynamicInstructions here
    }

    if creativityLevel == .high {
      // put additional DynamicInstructions here
    }
  }
}

func getTemperatureForCreativity(creativityLevel: CreativityLevel) -> Double {
  switch creativityLevel {
  case .low:
    return 0.3
  case .medium:
    return 0.5
  case .high:
    return 0.8
  }
}

struct CreativityProfile: LanguageModelSession.DynamicProfile {
  // tracks which creativity mode the app is in
  var creativityLevel: CreativityLevel = .low

  var body: some LanguageModelSession.DynamicProfile {
    // based on the creativity level, choose which instructions we want, and include other model modifiers
    switch creativityLevel {
    case .low:
      Profile {
        CreativityInstructions()
      }
      .temperature(getTemperatureForCreativity(creativityLevel: .low))
    //            .reasoningLevel(.light)   //you could use .reasoning with something like the PrivateCloudCompute model
    case .medium:
      Profile {
        CreativityInstructions(creativityLevel: creativityLevel)
      }
      .temperature(getTemperatureForCreativity(creativityLevel: .medium))
    //            .reasoningLevel(.moderate)
    case .high:
      Profile {
        CreativityInstructions(creativityLevel: creativityLevel)
      }
      .temperature(getTemperatureForCreativity(creativityLevel: .high))
    //            .reasoningLevel(.deep)
    }
  }
}

enum TaglineEnhancer {
  static func generate(
    from sourceTagline: String,
    creativityLevel: CreativityLevel = .low
  ) async throws -> String {
    let model = SystemLanguageModel.default

    guard model.availability == .available else {
      return fallbackEnhancement(for: sourceTagline)
    }

    let session = LanguageModelSession(
      profile: CreativityProfile(creativityLevel: creativityLevel)
    )

    let response = try await session.respond(
      to:
        "Rewrite this tagline into a single over-the-top marketing line packed with buzzwords, momentum, and confidence. Keep the core meaning intact. Tagline: \(sourceTagline)",
      generating: EnhancedTagline.self
    )

    let value = response.content.text.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let enhancedTaglineOrError =
      value.isEmpty ? fallbackEnhancement(for: sourceTagline) : value
    TaglineDataManager.shared.taglines.append(
      Tagline(
        id: sourceTagline,
        originalTagline: sourceTagline,
        enhancedTagline: enhancedTaglineOrError,
        model: "System",
        temperature: getTemperatureForCreativity(
          creativityLevel: creativityLevel
        )
      )
    )
    return enhancedTaglineOrError
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
