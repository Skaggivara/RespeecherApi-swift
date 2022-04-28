//
//  RespeechApi.swift
//  Chroma recorder
//
//  Created by Isak Wiström on 2022-03-16.
//

import Foundation
import Alamofire

// https://gateway.respeecher.com/api/docs

public enum RespeechApiError: Equatable {
    case uploadFailed, authFailed, requestFailed(String? = nil)
}

public struct RespeecherGroup: Codable {
    let id: String
    let name: String
    enum CodingKeys: String, CodingKey {
        case id, name
    }
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct RespeecherUser: Codable {
    let id: String
    let email: String
    let verified: Bool
    let username: String
    let first_name: String
    let last_name: String
    let roles: [String]
    let groups: [RespeecherGroup]

    public init(id: String, email: String, verified: Bool, username: String, first_name: String, last_name: String, roles: [String], groups: [RespeecherGroup]) {
        self.id = id
        self.email = email
        self.verified = verified
        self.username = username
        self.first_name = first_name
        self.last_name = last_name
        self.roles = roles
        self.groups = groups
    }
}

public struct RespeecherLoginResponse: Codable {
    let user: RespeecherUser
    let csrfToken : String

    enum CodingKeys: String, CodingKey {
        case user
        case csrfToken = "csrf_token"
    }

    public init(user: RespeecherUser, csrfToken: String) {
        self.user = user
        self.csrfToken = csrfToken
    }
}

public struct RespeecherRecording: Codable {

    let id: String
    let phraseId: String
    let type: String
    let url: String?
    let name: String
    let takeNumber: Int
    let state: String
    let originalId: String?
    let modelId: String?
    let modelName: String?
    let microphone: String
    let size: Int
    let starred: Bool
    let error: String
    let createdAt: String
    let convertedAt: String?
    let tts: Bool
    let ttsVoice: String?
    let text: String?

    var displayName: String {
        get {
            if type == "original" {
                var t = "#Take \(takeNumber) (original)"
                if tts {
                    t = "\(t) - (tts: '\(text ?? "Unknown")')"
                }
                return t
            }
            var status = "In progress"
            if let _ = convertedAt {
                status = "Completed"
            }
            var model = "Unknown"
            if let modelName = modelName {
                 model = modelName
            }
            return "#Take \(takeNumber), Model: \(model) (\(status))"
        }
    }

    var exportName: String {
        get {
            if type == "original" {
                var t = "#Take \(takeNumber) (original)"
                if tts {
                    t = "\(t) - (tts: '\(text ?? "Unknown")')"
                }
                return t
            }
            var model = "Unknown"
            if let modelName = modelName {
                 model = modelName
            }
            return "#Take \(takeNumber), Model: \(model)"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, url, name, state, microphone, size, starred, error, tts, text
        case ttsVoice = "tts_voice"
        case phraseId = "phrase_id"
        case createdAt = "created_at"
        case convertedAt = "converted_at"
        case takeNumber = "take_number"
        case originalId = "original_id"
        case modelId = "model_id"
        case modelName = "model_name"
    }

    public init(id: String,
                phraseId: String,
                type: String,
                url: String?,
                name: String,
                takeNumber: Int,
                state: String,
                originalId: String?,
                modelId: String?,
                modelName: String?,
                microphone: String,
                size: Int,
                starred: Bool,
                error: String,
                createdAt: String,
                convertedAt: String?,
                tts: Bool,
                ttsVoice: String?,
                text: String?) {
        self.id = id
        self.phraseId = phraseId
        self.type = type
        self.url = url
        self.name = name
        self.takeNumber = takeNumber
        self.state = state
        self.originalId = originalId
        self.modelId = modelId
        self.modelName = modelName
        self.microphone = microphone
        self.size = size
        self.starred = starred
        self.error = error
        self.createdAt = createdAt
        self.convertedAt = convertedAt
        self.tts = tts
        self.ttsVoice = ttsVoice
        self.text = text
    }

    public func localPath() -> URL? {
        guard let urlString = self.url, let url = URL(string: urlString) else { return nil }
        let fileName = url.lastPathComponent
        let directoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destURL = directoryURL.appendingPathComponent(fileName)
        return destURL
    }

    public func fileExists() -> Bool {
        guard let localPath = self.localPath() else { return false }
        if FileManager.default.fileExists(atPath: localPath.path) {
            return true
        }
        return false
    }
}

public struct RespeecherPhrase: Codable {
    let id: String
    let projectId: String
    let text: String
    let active: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, text, active
        case projectId = "project_id"
        case createdAt = "created_at"
    }

    public init(id: String, projectId: String, text: String, active: Bool, createdAt: String) {
        self.id = id
        self.projectId = projectId
        self.text = text
        self.active = active
        self.createdAt = createdAt
    }
}

public struct RespeecherModelParam: Codable {
    let id: String
    let alias: String
    let locked: String?
    let type: String
    let defaultValue: String
    let workerId: String

    enum CodingKeys: String, CodingKey {
        case id, alias, locked, type
        case defaultValue = "default"
        case workerId = "worker_id"
    }

    public init(id: String, alias: String, locked: String?, type: String, defaultValue: String, workerId: String) {
        self.id = id
        self.alias = alias
        self.locked = locked
        self.type = type
        self.defaultValue = defaultValue
        self.workerId = workerId
    }
}

public struct RespeecherModel: Codable {
    let id: String
    let name: String
    let owner: String
    let visibility: String
    let m2o: Bool
    let dateCreated: String
    let params: [RespeecherModelParam]

    enum CodingKeys: String, CodingKey {
        case id, name, owner, visibility, m2o, params
        case dateCreated = "date_created"
    }

    public init(id: String, name: String, owner: String, visibility: String, m2o: Bool, dateCreated: String, params: [RespeecherModelParam]) {
        self.id = id
        self.name = name
        self.owner = owner
        self.visibility = visibility
        self.m2o = m2o
        self.dateCreated = dateCreated
        self.params = params
    }

    public func defaultParams() -> [[String: Any]] {
        var ps: [[String: Any]] = []
        for p in params {
            ps.append([
                "id": p.id,
                "name": p.alias,
                "value": p.defaultValue
            ])
        }
        return ps
    }
}

public struct RespeecherProject: Codable {
    let id: String
    let active: Bool
    let createdAt: String
    let slug: String
    let owner: String
    let url: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, active, slug, owner, url, name
        case createdAt = "created_at"
    }

    public init(id: String, active: Bool, createdAt: String, slug: String, owner: String, url: String, name: String) {
        self.id = id
        self.active = active
        self.createdAt = createdAt
        self.slug = slug
        self.owner = owner
        self.url = url
        self.name = name
    }
}

public struct RespeecherVoice: Codable {
    let code: String
    let name: String
    let gender: String
    var apiCode: String? = nil

    var displayName: String {
        return "\(name) - \(gender)"
    }

    enum CodingKeys: String, CodingKey {
        case code, name, gender
    }

    public init(code: String, name: String, gender: String) {
        self.code = code
        self.name = name
        self.gender = gender
    }
}

public struct RespeecherErrorResponse: Codable {
    let detail: String
    enum CodingKeys: String, CodingKey {
        case detail
    }
    public init(detail: String) {
        self.detail = detail
    }
}

public struct RespeecherErrorValidation: Codable {
    let loc: [String]
    let msg: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case loc, msg, type
    }
    public init(loc: [String], msg: String, type: String) {
        self.loc = loc
        self.msg = msg
        self.type = type
    }
}

public struct RespeecherErrorValidationResponse: Codable {
    let detail: [RespeecherErrorValidation]
    enum CodingKeys: String, CodingKey {
        case detail
    }
    public init(detail: [RespeecherErrorValidation]) {
        self.detail = detail
    }
}

public struct RespeecherVoiceResponse: Codable {
    let voices: [RespeecherVoice]

    enum CodingKeys: String, CodingKey {
        case voices
    }

    public init(voices: [RespeecherVoice]) {
        self.voices = voices
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let voicesData = try container.decode([String: RespeecherVoice].self, forKey: .voices)
        var list: [RespeecherVoice] = []
        for (index, _) in voicesData.enumerated() {
            let key = Array(voicesData.keys)[index]
            var obj = Array(voicesData.values)[index]
            obj.apiCode = key
            list.append(obj)
        }
        voices = list
    }
}

public protocol RespeechApiAuthDelegate: AnyObject {
    func authStatusChanged(_ sender: RespeechApi, authenticated: Bool)
}

public class RespeechApi {

    static var endPoint = "https://gateway.respeecher.com/api/"

    private let tokenKey: String = "respeecher_token"
    private let cookieKey: String = "respeecher_savedCookies"

    static let loginPath = endPoint + "login"
    static let modelPath = endPoint + "models"
    static let projectPath = endPoint + "projects"
    static let phrasePath = endPoint + "phrases"
    static let recordingPath = endPoint + "recordings"
    static let orderPath = endPoint + "recordings/conversion-order"
    static let voicePath = endPoint + "tts-voice"
    static let voiceCreatePath = endPoint + "recordings/tts"

    static let allowedFileTypes: [String] = ["wav", "ogg", "mp3", "flac"]

    private(set) var isAuthenticated: Bool = false {
        didSet {
            delegate?.authStatusChanged(self, authenticated: isAuthenticated)
        }
    }
    private(set) var isAutenticating: Bool = false

    private(set) var token: String = ""

    weak var delegate: RespeechApiAuthDelegate?

    var tokenHeaders: HTTPHeaders {
        get {
            return ["x-csrf-token": token, "Content-type application": "json", "Accept application": "json"]
        }
    }

    public init() {
        self.loadExisting()
    }

    private func loadExisting() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            self.token = token
        }
        if self.token.count > 0, let _ = UserDefaults.standard.array(forKey: cookieKey) as? [[HTTPCookiePropertyKey: Any]] {
            self.isAuthenticated = true
        }
        loadCookies()
    }

    private func saveToken() {
        UserDefaults.standard.set(self.token, forKey: tokenKey)
        UserDefaults.standard.synchronize()
    }

    private func clearToken() {
        token = ""
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    private func clearCookies() {
        guard let cookieArray = UserDefaults.standard.array(forKey: cookieKey) as? [[HTTPCookiePropertyKey: Any]] else { return }
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }

    private func saveCookies(response: DataResponse<RespeecherLoginResponse, AFError>) {
        let headerFields = response.response?.allHeaderFields as! [String: String]
        let url = response.response?.url
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
        var cookieArray = [[HTTPCookiePropertyKey: Any]]()
        for cookie in cookies {
            cookieArray.append(cookie.properties!)
        }
        UserDefaults.standard.set(cookieArray, forKey: cookieKey)
        UserDefaults.standard.synchronize()
    }

    private func loadCookies() {
        guard let cookieArray = UserDefaults.standard.array(forKey: cookieKey) as? [[HTTPCookiePropertyKey: Any]] else { return }
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    private func request<T: Decodable>(_ path: String, method: HTTPMethod, parameters: [String:Any]?, encoding: ParameterEncoding = JSONEncoding.default, headers: HTTPHeaders?, completion: @escaping (T) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        if !isAuthenticated {
            onFailure(.authFailed)
            return
        }
        AF.request(path, method: method, parameters: parameters, encoding: encoding, headers: headers).responseDecodable(of: T.self) { response in
            switch response.result {
            case .success:
                if let responseCode = response.response?.statusCode, responseCode < 400, let result = response.value {
                    completion(result)
                    return
                }
            case .failure:
                break
            }
            if let responseCode = response.response?.statusCode, (401...403).contains(responseCode) {
                self.isAuthenticated = false
                onFailure(.authFailed)
            } else {
                onFailure(.requestFailed())
            }
        }
    }

    @discardableResult
    public func logout() -> Bool {
        if !isAuthenticated || isAutenticating {
            return false
        }
        isAuthenticated = false
        clearCookies()
        clearToken()
        return true
    }

    public func login(username: String, password: String, completion: ((Bool) -> Void)? = nil) {

        let parameters: [String: Any] = [
            "email": username,
            "password": password
        ]

        isAutenticating = true
        isAuthenticated = false

        clearCookies()

        AF.request(RespeechApi.loginPath, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseDecodable(of: RespeecherLoginResponse.self) { response in
            switch response.result {
            case .success:
                if let responseCode = response.response?.statusCode, responseCode < 400, let loginResponse = response.value {
                    self.token = loginResponse.csrfToken
                    self.isAuthenticated = true
                    self.saveCookies(response: response)
                    self.saveToken()
                }
            case .failure:
                break
            }
            self.isAutenticating = false
            completion?(self.isAuthenticated)
        }
    }

    public func fetchProjects(completion: @escaping ([RespeecherProject]) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        request(RespeechApi.projectPath, method: .get, parameters: nil, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func createProject(_ name: String, completion: @escaping (RespeecherProject) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "name": name
        ]
        request(RespeechApi.modelPath, method: .post, parameters: parameters, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func fetchModels(completion: @escaping ([RespeecherModel]) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        request(RespeechApi.modelPath, method: .get, parameters: nil, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func createTTS(phraseId: String, voice: String, text: String, completion: @escaping (RespeecherRecording?) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "phrase_id": phraseId,
            "text": text,
            "voice": voice
        ]
        request(RespeechApi.voiceCreatePath, method: .post, parameters: parameters, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func fetchTTSVoices(completion: @escaping (RespeecherVoiceResponse) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        request(RespeechApi.voicePath, method: .get, parameters: nil, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    //  Supported extensions: ['wav', 'ogg', 'mp3', 'flac']
    public func createRecording(phraseId: String, recording: Data, fileName: String = "recording.wav", mimeType: String = "audio/wav", completion: @escaping (RespeecherRecording?) -> Void, onProgress: @escaping (Double) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        if !isAuthenticated {
            onFailure(.authFailed)
            return
        }
        let parameters: [String: Any] = [
            "phrase_id": phraseId,
            "microphone": fileName
        ]

        AF.upload(multipartFormData: { multiPart in
            for (key, value) in parameters {
                if let temp = value as? String {
                    multiPart.append(temp.data(using: .utf8)!, withName: key)
                }
            }
            multiPart.append(recording, withName: "data", fileName: fileName, mimeType: mimeType)
        }, to: RespeechApi.recordingPath, method: .post, headers: tokenHeaders)
            .uploadProgress(queue: .main, closure: { progress in
                onProgress(progress.fractionCompleted)
            })
            .responseDecodable(of: RespeecherRecording.self) { response in
                switch response.result {
                case .success:
                    if let responseCode = response.response?.statusCode, responseCode < 400, let recording = response.value {
                        completion(recording)
                        return
                    }
                case .failure:
                    break
                }
                if let responseCode = response.response?.statusCode, (401...403).contains(responseCode) {
                    self.isAuthenticated = false
                    onFailure(.authFailed)
                } else {
                    onFailure(.requestFailed())
                }
            }
    }

    public func fetchRecordings(phraseId: String, completion: @escaping ([RespeecherRecording]) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "phrase_id": phraseId
        ]
        request(RespeechApi.recordingPath, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func createOrder(originalId: String, modelId: String, modelName: String, modelParams: [[String: Any]], completion: @escaping ([RespeecherRecording]) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "original_id": originalId,
            "models": [
                [
                    "id": modelId,
                    "name": modelName,
                    "params": modelParams
                ]
            ]
        ]
        request(RespeechApi.orderPath, method: .post, parameters: parameters, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func downloadRecording(_ recording: RespeecherRecording, completion: @escaping (String) -> Void, onProgress: @escaping (Double) -> Void,  onFailure: @escaping (RespeechApiError) -> Void) {
        if !isAuthenticated {
            onFailure(.authFailed)
            return
        }
        guard let urlString = recording.url, let url = URL(string: urlString) else {
            onFailure(.requestFailed())
            return
        }

        if recording.fileExists() {
            onFailure(.requestFailed())
            return
        }

        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)

        let parameters: [String: Any] = [
            "token": self.token
        ]

        AF.download(url,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            to: destination).downloadProgress(closure: { (progress) in
                onProgress(progress.fractionCompleted)
        }).response(completionHandler: { (response) in
            switch response.result {
            case .success:
                if let responseCode = response.response?.statusCode, responseCode < 400 {
                    completion(response.fileURL?.absoluteString ?? "")
                    return
                }
            case .failure:
               break
            }
            if let responseCode = response.response?.statusCode, (401...403).contains(responseCode) {
                self.isAuthenticated = false
                onFailure(.authFailed)
            } else {
                onFailure(.requestFailed())
            }
        })
    }

    public func createPhrase(projectId: String, phrase: String, completion: @escaping (RespeecherPhrase) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "project_id": projectId,
            "text": phrase
        ]
        request(RespeechApi.phrasePath, method: .post, parameters: parameters, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func updatePhrase(phraseId: String, text: String, completion: @escaping (RespeecherPhrase) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "text": text
        ]
        let path = "\(RespeechApi.phrasePath)/\(phraseId)"
        request(path, method: .put, parameters: parameters, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func deletePhrase(phraseId: String, completion: @escaping (RespeecherPhrase) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let path = "\(RespeechApi.phrasePath)/\(phraseId)"
        request(path, method: .delete, parameters: nil, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }

    public func fetchPhrases(projectId: String, completion: @escaping ([RespeecherPhrase]) -> Void, onFailure: @escaping (RespeechApiError) -> Void) {
        let parameters: [String: Any] = [
            "project_id": projectId
        ]
        request(RespeechApi.phrasePath, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: tokenHeaders, completion: completion, onFailure: onFailure)
    }
}
