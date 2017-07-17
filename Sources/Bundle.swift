//
//  Bundle.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
struct Bundle {
    init(for: Any.Type) {}

    func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        let subpath = subpath ?? ""
        var files = [String]()
        guard let dir = opendir(subpath) else { return files }
        while let file = readdir(dir) {
            withUnsafePointer(to: &file.pointee.d_name, { pointer in
                let filename = pointer.withMemoryRebound(to: CChar.self, capacity: Int(file.pointee.d_namlen), String.init)
                if let ext = ext, !filename.hasSuffix(ext) { return }
                files.append(filename)
            })
        }

        closedir(dir)
        return files
    }
}
#endif

