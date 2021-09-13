@testable import Flow
import XCTest

final class FlowAPITests: XCTestCase {
//    var flowAPI: Flow.API!
//
//    override func setUp() {
//        super.setUp()
//        Flow.shared.config.put(key: .wallet,
//                               value: "https://29729fab-f834-4126-90c4-a4c2f9844c9d.mock.pstmn.io")
//        flowAPI = API()
//    }
//
//    func testAuthn() throws {
    ////        let result = try flowAPI.authn().wait()
    ////        XCTAssertNotNil(result)
//    }

    func testAnything() {
        let settings = buildTransaction {
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
                [Flow.Argument(value: .string(value: "111"))]
            }
        }

        settings.build()
    }
}
