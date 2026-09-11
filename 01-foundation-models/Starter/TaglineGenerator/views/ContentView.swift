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

import FoundationModels
import GeoToolbox
import SwiftUI
import UniformTypeIdentifiers

@main
struct TaglineGeneratorApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var sourceTagline = ""
  @State private var enhancedTagline = ""
  @State private var generationState: GenerationState = .idle
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.08, green: 0.10, blue: 0.15),
            Color(red: 0.20, green: 0.12, blue: 0.28),
            Color(red: 0.08, green: 0.17, blue: 0.20)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            header
            inputCard
            outputCard
          }
          .padding()
          .frame(maxWidth: 760)
          .frame(maxWidth: .infinity, alignment: .center)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Buzzword engine")
        .font(.caption.weight(.semibold))
        .textCase(.uppercase)
        .foregroundStyle(.white.opacity(0.72))

      Text("Turn plain taglines into over-the-top marketing copy.")
        .font(.largeTitle.bold())
        .foregroundStyle(.white)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(24)
    .background(
      .white.opacity(0.08),
      in: RoundedRectangle(cornerRadius: 28, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(.white.opacity(0.16), lineWidth: 1)
    )
  }

  private var inputCard: some View {
    card(title: "Original tagline", systemImage: "sparkles") {
      VStack(alignment: .leading, spacing: 16) {
        TextField(
          "Enter a plain tagline",
          text: $sourceTagline,
          axis: .vertical
        )
        .textFieldStyle(.roundedBorder)
        .lineLimit(3, reservesSpace: true)

        Button {
          Task {
            await enhanceTagline()
          }
        } label: {
          HStack {
            if generationState == .generating {
              ProgressView()
                .tint(.white)
            }
            Text(
              generationState == .generating ? "Enhancing" : "Enhance tagline"
            )
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.98, green: 0.55, blue: 0.18))
        .disabled(
          sourceTagline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || generationState == .generating
        )

        if let errorMessage {
          Text(errorMessage)
            .font(.footnote)
            .foregroundStyle(.red.opacity(0.92))
        }

        Text(statusText)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var outputCard: some View {
    card(title: "Enhanced tagline", systemImage: "quote.opening") {
      VStack(alignment: .leading, spacing: 16) {
        Text(
          enhancedTagline.isEmpty
            ? "The enhanced tagline will appear here." : enhancedTagline
        )
        .font(.title3.weight(.semibold))
        .foregroundStyle(enhancedTagline.isEmpty ? .secondary : .primary)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          .thinMaterial,
          in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )

        HStack {
          Button {
            enhancedTagline = sourceTagline
          } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
          }
          .buttonStyle(.borderless)

          Spacer()

          Button {
            sourceTagline = enhancedTagline
          } label: {
            Label("Use as input", systemImage: "text.cursor")
          }
          .buttonStyle(.borderless)
          .disabled(enhancedTagline.isEmpty)
        }
        .font(.callout)
      }
    }
  }

  private var statusText: String {
    switch generationState {
    case .idle:
      return
        "Foundation Models will be used when the system model is available."
    case .generating:
      return "Generating a more exuberant version now."
    case .completed:
      return "Ready to send or refine again."
    case .unavailable:
      return
        "The system model is unavailable, so the app is falling back to a local rewrite pattern."
    }
  }

  private func card<Content: View>(
    title: String,
    systemImage: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(title, systemImage: systemImage)
        .font(.headline)
        .foregroundStyle(.white)
      content()
    }
    .padding(20)
    .background(
      .white.opacity(0.08),
      in: RoundedRectangle(cornerRadius: 24, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(.white.opacity(0.12), lineWidth: 1)
    )
  }

  @MainActor
  private func enhanceTagline() async {
  }
}

private enum GenerationState {
  case idle
  case generating
  case completed
  case unavailable
}

#Preview {
  ContentView()
}
