import XCTest
@testable import RespeecherApi
import Mocker
import Alamofire

public final class RespeecherMockedData {
    public static let loginSuccess: URL = Bundle.module.url(forResource: "resources/login_success", withExtension: "json")!
    public static let loginFail: URL = Bundle.module.url(forResource: "resources/login_fail", withExtension: "json")!
    public static let modelsSuccess: URL = Bundle.module.url(forResource: "resources/models_success", withExtension: "json")!
    public static let modelsFail: URL = Bundle.module.url(forResource: "resources/models_fail", withExtension: "json")!
}

final class RespeecherApiTests: XCTestCase {

    static var respeecherLoginURL = URL(string: RespeechApi.loginPath)!
    let respeecherLoginMock = Mock(url: respeecherLoginURL, dataType: .json, statusCode: 200, data: [
        .get : try! Data(contentsOf: RespeecherMockedData.loginSuccess)
    ])

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let _ = Alamofire.Session(configuration: configuration)
        respeecherLoginMock.register()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK - respeecher tests
    func testRespeecherLoginSuccess() throws {
        let api = RespeechApi()
        api.login(username: "test", password: "test") { success in
            XCTAssertTrue(success)
            XCTAssertTrue(api.isAuthenticated)
        }
    }

    func testRespeecherLoginFail() throws {
        let originalURL = URL(string: RespeechApi.loginPath)!
        let mock = Mock(url: originalURL, dataType: .json, statusCode: 403, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.loginFail)
        ])
        mock.register()

        let api = RespeechApi()
        api.logout()
        api.login(username: "test", password: "test") { success in
            XCTAssertFalse(success)
        }
    }

    func testRespeecherModelsSuccess() throws {
        let modelsURL = URL(string: RespeechApi.modelPath)!

        let modelsMock = Mock(url: modelsURL, dataType: .json, statusCode: 200, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.modelsSuccess)
        ])
        modelsMock.register()

        let api = RespeechApi()
        api.login(username: "test", password: "test") { success in
            api.fetchModels { models in
                XCTAssertTrue(models.count == 1)
                XCTAssertTrue(models[0].name == "string")
            } onFailure: { error in
                debugPrint(error)
            }
        }
    }

    func testRespeecherModelsFail() throws {
        let modelsURL = URL(string: RespeechApi.modelPath)!
        let modelsMock = Mock(url: modelsURL, dataType: .json, statusCode: 400, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.modelsFail)
        ])
        modelsMock.register()

        let api = RespeechApi()
        api.login(username: "test", password: "test") { success in
            api.fetchModels { models in
                debugPrint(models)
            } onFailure: { error in
                XCTAssertTrue(error == .requestFailed())
            }
        }
    }
}
