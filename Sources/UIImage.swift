import SDL
import SDL_gpu
import RegexBuilder
#if canImport(_StringProcessing)
import _StringProcessing
#endif

@MainActor // UIImage is MainActor but CGImage is not
public class UIImage {
    public let cgImage: CGImage
    public let size: CGSize
    public let scale: CGFloat

    public init(cgImage: CGImage, scale: CGFloat) {
        self.cgImage = cgImage
        self.scale = scale
        self.size = CGSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
    }

    /// As on iOS: if no file extension is provided, assume `.png`.
    public convenience init?(named name: String) {
        let (pathWithoutExtension, fileExtension) = name.pathAndExtension()

        // e.g. ["@3x", "@2x", ""]
        let scale = Int(UIScreen.main.scale.rounded())
        let possibleScaleStrings = stride(from: scale, to: 1, by: -1)
            .map { "@\($0)x" }
            + [""] // it's possible to have no scale string (e.g. "image.png")

        for scaleString in possibleScaleStrings {
            let attemptedFilePath = "\(pathWithoutExtension)\(scaleString)\(fileExtension)"
            if let data = Data._fromPathCrossPlatform(attemptedFilePath) {
                self.init(data: data, scale: attemptedFilePath.extractImageScale())
                return
            }
        }

        print("Couldn't find image named", name)

        return nil
    }

    public convenience init?(path: String) {
        guard let data = Data._fromPathCrossPlatform(path) else { return nil }
        self.init(data: data, scale: path.extractImageScale())
    }

    public convenience init?(data: Data) {
        self.init(data: data, scale: 1.0) // matches iOS
    }

    private convenience init?(data: Data, scale: CGFloat) {
        guard let cgImage = CGImage(data) else {
            return nil
        }

        self.init(cgImage: cgImage, scale: scale)
    }
    
    public func resizableImage(withCapInsets capInsets: UIEdgeInsets) -> UIImage {
        return self
    }
}

private extension String {
    func pathAndExtension() -> (pathWithoutExtension: String, fileExtension: String) {
        let regex = Regex {
            Capture {
                OneOrMore(.any, .reluctant)
            }
            Optionally {
                Capture {
                    "."
                    OneOrMore(.word)
                    Anchor.endOfLine
                }
            }
        }

        let path = self.asAbsolutePath()
        let result = try! regex.wholeMatch(in: path)!

        return (String(result.1), String(result.2 ?? ".png"))
    }

    func extractImageScale() -> CGFloat {
        let regex = Regex {
            "@"
            TryCapture { One(.digit) } transform: { CGFloat($0) }
            "x"
            Optionally {
              "."
              OneOrMore(CharacterClass(.word))
            }
        }

        if let result = self.firstMatch(of: regex) {
            return result.output.1
        }

        return 1.0
    }

    private func asAbsolutePath() -> String {
        #if os(macOS)
        if !self.hasPrefix("/") {
            return Bundle(for: UIImage.self).path(forResource: self, ofType: nil) ?? self
        }
        // Mac can fall through to the following code if we already have an absolute path:
        #endif
        // Android doesn't need absolute paths:
        return self
    }
}
