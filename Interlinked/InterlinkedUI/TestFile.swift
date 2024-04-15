import SwiftUI

struct Item: Identifiable, Decodable {
    let id: Int
    let description: String

    init(id: Int, description: String) {
        self.id = id
        self.description = description
    }
    
    enum CodingKeys: CodingKey {
        case id
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.description = try container.decode(String.self, forKey: .description)
    }
}

class ViewModel: ObservableObject {
    let value3: String

    init(value3: String) {
        self.value3 = value3
    }

    func newFunc(
        value: String,
        awdawdawdawdawdawdawdawd: @escaping () -> Void
    ) {
        print("")
    }

    private func newVal() {

    }
}

