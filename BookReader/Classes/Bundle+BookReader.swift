//
//  Bundle+BookReader.swift
//
//  Created by Alex on 01/10/2018.
//

import Foundation

internal class DummyBookReaderClass {}

extension Bundle {
    static var bookReader: Bundle {
        get {
            let bundle = Bundle(for: DummyBookReaderClass.self)
            let bookReaderBundlePath = bundle.path(forResource: "BookReader", ofType: "bundle")
            return Bundle(path: bookReaderBundlePath!)!
        }
    }
}
