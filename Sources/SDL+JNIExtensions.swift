//
//  SDL+JNIExtensions.swift
//  UIKit
//
//  Created by Geordie Jay on 27.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

@_silgen_name("Android_JNI_GetActivityClass")
public func getActivityClass() -> JavaClass
