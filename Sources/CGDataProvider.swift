//
//  CGDataProvider.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL

public class CGDataProvider {
    public let data: CFData?

    public init?(data: CFData) {
        self.data = data
    }

    public init?(filepath: String) {
        guard let fileReader = SDL_RWFromFile(filepath, "r") else { return nil }
        defer { _ = fileReader.pointee.close(fileReader) }

        let fileLength = Int(fileReader.pointee.size(fileReader))
        var data = Data(repeating: 0, count: fileLength)
        guard fileReader.pointee.read(fileReader, &data, 1, fileLength) == fileLength else {
            print("fileSize was incorrect when reading \(filepath)")
            return nil
        }

        self.data = data
    }
}
