import BigInt
import CryptoKit
@testable import Flow
import XCTest

final class FlowAccessAPITests: XCTestCase {
    var flowAPI: FlowAccessAPI!
    var testAddress = "7907881e2e2cdfb7"
    var mainnetAddress = "0x4eb165aa383fd6f9"

    let publicKey = try! P256.KeyAgreement.PublicKey(rawRepresentation: "d487802b66e5c0498ead1c3f576b718949a3500218e97a6a4a62bf69a8b0019789639bc7acaca63f5889c1e7251c19066abb09fcd6b273e394a8ac4ee1a3372f".hexValue)
    let privateKey = try! P256.Signing.PrivateKey(rawRepresentation: "c9c0f04adddf7674d265c395de300a65a777d3ec412bba5bfdfd12cffbbb78d9".hexValue)

    override func setUp() {
        super.setUp()
        let flowInstance = Flow.shared
        flowAPI = flowInstance.newAccessApi(chainId: .mainnet)
    }

    func testFlowPing() throws {
        let isConnected = try flowAPI.ping().wait()
        XCTAssertTrue(isConnected)
    }

    func testNetworkParameters() throws {
        let chainId = try flowAPI.getNetworkParameters().wait()
        XCTAssertEqual(chainId, Flow.ChainId.mainnet)
    }

    func testBlockHeader() throws {
        let blockHeader = try flowAPI.getLatestBlockHeader().wait()
        XCTAssertNotNil(blockHeader)
    }

    func testGetAccount() throws {
        let address = Flow.Address(hex: mainnetAddress)
        let account = try flowAPI.getAccountAtLatestBlock(address: address).wait()
        XCTAssertNotNil(account?.keys.first)
        XCTAssertEqual(address, account?.address)
    }

    func testGetBlockHeaderByID() throws {
        let block = try flowAPI.getLatestBlock(sealed: true).wait()
        XCTAssertNotNil(block)

        let blockHeader = try flowAPI.getBlockById(id: block.id).wait()
        XCTAssertNotNil(blockHeader)
        XCTAssertEqual(blockHeader?.height, block.height)
    }

    func testGetAccountByHeight() throws {
        let address = Flow.Address(hex: mainnetAddress)
        let block = try flowAPI.getLatestBlock(sealed: true).wait()
        XCTAssertNotNil(block)
        let account = try flowAPI.getAccountByBlockHeight(address: address, height: block.height).wait()
        XCTAssertNotNil(account?.keys.first)
        XCTAssertEqual(address, account?.address)
    }

    func testGetLatestBlock() throws {
        let block = try flowAPI.getLatestBlock(sealed: true).wait()
        XCTAssertNotNil(block)
    }

    func testGetLatestProtocolStateSnapshot() throws {
        let snapshot = try flowAPI.getLatestProtocolStateSnapshot().wait()
        XCTAssertNotNil(snapshot)
    }

    func testSendTransaction() throws {
        // TODO:
        let testnetAPI = Flow.shared.newAccessApi(chainId: .testnet)!
        let address = Flow.Address(hex: "0xc6de0d94160377cd")
        let accountKey = Flow.AccountKey(publicKey: Flow.PublicKey(hex: privateKey.publicKey.rawRepresentation.hexValue),
                                         signAlgo: .ECDSA_P256,
                                         hashAlgo: .SHA2_256,
                                         weight: 1000)

        let argument = Flow.Argument(value: .string(value: accountKey.encoded!.hexValue))

        let unsignedTx = buildSimpleTransaction(chainId: .testnet, address: address) {
            script {
                """
                    transaction(publicKey: String) {
                        prepare(signer: AuthAccount) {
                            let account = AuthAccount(payer: signer)
                            account.addPublicKey(publicKey.decodeHex())
                        }
                    }
                """
            }

            arguments {
                [argument]
            }
        }

        guard let data = unsignedTx?.encodedEnvelope else {
            XCTFail("RLP encode error")
            return
        }

        let signableData = Flow.Constants.transactionPrefix + data.hexValue
        let sign = try! signTransaction(signableData: signableData.hexValue.data)
        let newTx = unsignedTx?.buildUpOn(envelopeSignatures: [
            Flow.TransactionSignature(address: address,
                                      signerIndex: 0,
                                      keyIndex: 0,
                                      signature: Flow.Signature(bytes: sign.byteArray)),
        ])

        let txId = try testnetAPI.sendTransaction(transaction: newTx!).wait()
        XCTAssertNotNil(txId)
        print(txId.hexValue)
    }

    func testGetCollectionById() throws {
        // Example for mainnet
//        let id = Flow.Id(hex: "53cc748124358855ec4d975ce6511ba016f5d2dfcead1527fd858579fc7baf76")
//        let collection = try flowAPI.getCollectionById(id: id).wait()
//        XCTAssertNotNil(collection)
    }

    func testTransactionById() throws {
        // Example for mainnet
        let id = Flow.Id(hex: "6d6c20405f3dd2001361cd994493a56d31f4daa1c7ce420a2cd4259454b4a0da")
        let transaction = try flowAPI.getTransactionById(id: id).wait()
        XCTAssertEqual(transaction?.arguments.first?.type, .path)
        XCTAssertEqual(transaction?.arguments.first?.value, .path(value: .init(domain: "public", identifier: "zelosAccountingTokenReceiver")))
        XCTAssertEqual(transaction?.arguments.last?.type, .ufix64)
        XCTAssertEqual(transaction?.arguments.last?.value, .ufix64(value: 99.0))
        XCTAssertEqual(transaction?.payerAddress.bytes.hexValue, "1f56a1e665826a52")
        XCTAssertNotNil(transaction)
    }

    func testTransactionResultById() throws {
        // Example for mainnet
        let id = Flow.Id(hex: "6d6c20405f3dd2001361cd994493a56d31f4daa1c7ce420a2cd4259454b4a0da")
        let result = try flowAPI.getTransactionResultById(id: id).wait()
        XCTAssertEqual(result?.events.count, 3)
        XCTAssertEqual(result?.events.first?.type, "A.c38aea683c0c4d38.Eternal.Withdraw")
        XCTAssertEqual(result?.events.first?.payload.fields?.type, .event)
        XCTAssertEqual(result?.events.first?.payload.fields?.value,
                       .event(value: .init(id: "A.c38aea683c0c4d38.Eternal.Withdraw",
                                           fields: [.init(name: "id", value: .init(value: .uint64(value: 11800))),
                                                    .init(name: "from", value: .init(value: .optional(value: .init(value: .address(value: .init(hex: "0x873becfb539f038d"))))))])))
        XCTAssertNotNil(result)
    }

    // SigAlgorithm: **ECDSA_P256**
    // HashAlgorithm: **SHA2_256**
    func signTransaction(signableData: Data) throws -> Data {
        let sig = try privateKey.signature(for: signableData)
        return sig.rawRepresentation

//        func composite(rawRepresentation: Data) -> (r: Data, s: Data) {
//            let combined = rawRepresentation
//            assert(combined.count % 2 == 0)
//            let half = combined.count / 2
//            return (combined.prefix(upTo: half), combined.suffix(from: half))
//        }
//
//        let (r, s) = composite(rawRepresentation: sig.rawRepresentation)
//        print("r -> \(r.toHexString())")
//        print("s -> \(s.toHexString())")
//        print("sig -> \(sig.rawRepresentation.toHexString())")
//        let result = pk.publicKey.isValidSignature(sig, for: data)
    }
}
