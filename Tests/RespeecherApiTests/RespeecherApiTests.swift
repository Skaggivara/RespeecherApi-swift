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

    var session: Session!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.af.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        session = Alamofire.Session(configuration: configuration)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK - respeecher tests
    func testRespeecherLoginSuccess() throws {
        let originalURL = URL(string: RespeechApi.loginPath)!
        let mock = Mock(url: originalURL, dataType: .json, statusCode: 200, data: [
            .post : try! Data(contentsOf: RespeecherMockedData.loginSuccess)
        ])
        mock.register()
        let expectation = self.expectation(description: "Login success")
        let api = RespeechApi(manager: session)
        api.login(username: "test", password: "test") { (success, user) in
            XCTAssertTrue(success)
            XCTAssertTrue(api.isAuthenticated)
            XCTAssertEqual(user!.email, "user@example.com")
            XCTAssertEqual(api.user!.email, "user@example.com")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRespeecherLoginFail() throws {
        let originalURL = URL(string: RespeechApi.loginPath)!
        let mock = Mock(url: originalURL, dataType: .json, statusCode: 403, data: [
            .post : try! Data(contentsOf: RespeecherMockedData.loginFail)
        ])
        mock.register()

        let expectation = self.expectation(description: "Login fail")

        let api = RespeechApi(manager: session)
        api.logout()
        api.login(username: "test", password: "test") { (success, user) in
            XCTAssertFalse(success)
            XCTAssertNil(user)
            XCTAssertNil(api.user)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRespeecherModelsSuccess() throws {
        let loginURL = URL(string: RespeechApi.loginPath)!
        let loginMock = Mock(url: loginURL, dataType: .json, statusCode: 200, data: [
            .post : try! Data(contentsOf: RespeecherMockedData.loginSuccess)
        ])
        loginMock.register()

        let modelsURL = URL(string: RespeechApi.modelPath)!
        let modelsMock = Mock(url: modelsURL, dataType: .json, statusCode: 200, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.modelsSuccess)
        ])
        modelsMock.register()

        let expectation = self.expectation(description: "Models success")

        let api = RespeechApi(manager: session)
        api.login(username: "test", password: "test") { (success, user) in
            api.fetchModels { models in
                XCTAssertTrue(models.count == 3)
                XCTAssertTrue(models[0].name == "Aaron")
                expectation.fulfill()
            } onFailure: { error in
                debugPrint(error)
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRespeecherModelsFail() throws {
        let loginURL = URL(string: RespeechApi.loginPath)!
        let loginMock = Mock(url: loginURL, dataType: .json, statusCode: 200, data: [
            .post : try! Data(contentsOf: RespeecherMockedData.loginSuccess)
        ])
        loginMock.register()

        let modelsURL = URL(string: RespeechApi.modelPath)!
        let modelsMock = Mock(url: modelsURL, dataType: .json, statusCode: 400, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.modelsFail)
        ])
        modelsMock.register()

        let expectation = self.expectation(description: "Models fail")

        let api = RespeechApi(manager: session)
        api.login(username: "test", password: "test") { (success, user) in
            api.fetchModels { models in
                debugPrint(models)
            } onFailure: { error in
                XCTAssertTrue(error == .requestFailed())
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRespeecherModelsPreview() throws {
        let loginURL = URL(string: RespeechApi.loginPath)!
        let loginMock = Mock(url: loginURL, dataType: .json, statusCode: 200, data: [
            .post : try! Data(contentsOf: RespeecherMockedData.loginSuccess)
        ])
        loginMock.register()

        let modelsURL = URL(string: RespeechApi.modelPath)!
        let modelsMock = Mock(url: modelsURL, dataType: .json, statusCode: 200, data: [
            .get : try! Data(contentsOf: RespeecherMockedData.modelsSuccess)
        ])
        modelsMock.register()

        let expectation = self.expectation(description: "Models preview")

        let api = RespeechApi(manager: session)
        api.login(username: "test", password: "test") { (success, user) in
            XCTAssertTrue(success)
            api.fetchModels { models in
                XCTAssertTrue(models.count == 3)
                XCTAssertTrue(models[0].name == "Aaron")
                XCTAssertTrue(models[1].name == "Plyukh (Dog)")
                XCTAssertTrue(models[2].name == "Fiona (Cat)")
                XCTAssertTrue(models[0].previewUrl == "\(RespeechApi.modelPreviewEndpoint)aaron_d.wav")
                XCTAssertTrue(models[1].previewUrl == "\(RespeechApi.modelPreviewEndpoint)dog-plyukh_d.wav")
                XCTAssertTrue(models[2].previewUrl == "\(RespeechApi.modelPreviewEndpoint)cat-fiona_d.wav")
                expectation.fulfill()
            } onFailure: { error in
                debugPrint(error)
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
