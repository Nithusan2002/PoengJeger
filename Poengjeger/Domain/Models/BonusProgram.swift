import Foundation

struct BonusProgram: Identifiable, Hashable {
    let id: UUID
    let slug: String
    let name: String
    let issuerName: String
    let countryCode: String
    let isActive: Bool
}
