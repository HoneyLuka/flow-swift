//
//  File.swift
//
//
//  Created by lmcmz on 21/7/21.
//

import Foundation

protocol Hasher {
    func hash(bytes: ByteArray) -> ByteArray
    func hashAsHexString(bytes: ByteArray) -> String
}

extension Hasher {
    func hashAsHexString(bytes: ByteArray) -> String {
        return hash(bytes: bytes).hexValue
    }
}

protocol Signer {
    var hasher: Hasher { get set }

    func sign(bytes: ByteArray) -> ByteArray

    func signWithDomain(bytes: ByteArray, domain: ByteArray) -> ByteArray

    func signAsUser(bytes: ByteArray) -> ByteArray

    func signAsTransaction(bytes: ByteArray) -> ByteArray
}
