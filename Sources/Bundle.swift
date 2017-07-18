//
//  Bundle.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
public struct Bundle {
    public init(for: Any.Type) {}

    public func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        let subpath = subpath ?? "."
        var files = [String]()
        let basePath = SDL_GetBasePath()
        guard let dir = opendir(subpath) else {
            print("opendir failed for subpath", subpath, "returning empty files array", files)
            return files
        }
        while let file = readdir(dir) {
            withUnsafePointer(to: &file.pointee.d_name, { pointer in
                let filename = pointer.withMemoryRebound(to: CChar.self, capacity: 1024, String.init)
                if ext == nil {
                    files.append(filename)
                } else if
                    let ext = ext,
                    strcmp(String(filename.characters.suffix(ext.characters.count)), ext) == 0
                {
                    files.append(filename)
                }
            })
        }

        closedir(dir)
        return files
    }

    public func path(forResource filename: String, ofType ext: String) -> String? {
        if ext.characters.first  == "." {
            return filename + ext
        } else {
            return filename + "." + ext
        }
    }
}
#endif

