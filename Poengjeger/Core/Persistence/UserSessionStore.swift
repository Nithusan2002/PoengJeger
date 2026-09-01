import Foundation

protocol UserSessionStore {
    func load() -> UserSession?
    func save(_ session: UserSession)
}

struct UserDefaultsUserSessionStore: UserSessionStore {
    private let writer: UserDefaultsSessionWriter
    private let saveQueue = DispatchQueue(label: "no.poengjeger.user-session-store", qos: .utility)

    init(defaults: UserDefaults = .standard) {
        writer = UserDefaultsSessionWriter(defaults: defaults, key: "no.poengjeger.user-session")
    }

    func load() -> UserSession? {
        guard let data = writer.loadData() else {
            return nil
        }

        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func save(_ session: UserSession) {
        let writer = writer

        saveQueue.async {
            guard let data = try? JSONEncoder().encode(session) else {
                return
            }

            writer.save(data)
        }
    }
}

private final class UserDefaultsSessionWriter: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func loadData() -> Data? {
        defaults.data(forKey: key)
    }

    func save(_ data: Data) {
        defaults.set(data, forKey: key)
    }
}

final class InMemoryUserSessionStore: UserSessionStore {
    private var session: UserSession?

    init(session: UserSession? = nil) {
        self.session = session
    }

    func load() -> UserSession? {
        session
    }

    func save(_ session: UserSession) {
        self.session = session
    }
}
