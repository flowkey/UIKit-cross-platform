//
//  AVPlayerItem+Mac.swift
//  FlowkeyPlayerSDL
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import struct Foundation.URL

public class AVPlayerItem {
    public var url: URL?
    public init(url: URL?) {
        self.url = url
    }
}
