import Foundation

protocol UserSessionStore {
    func load() -> UserSession?
    func save(_ session: UserSession)
}

struct UserDefaultsUserSessionStore: UserSessionStore {
    private let defaults: UserDefaults
    private let key = "no.poengjeger.user-session"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSession? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func save(_ session: UserSession) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

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
