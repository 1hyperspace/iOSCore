import Foundation

struct Person: Storable, Equatable {
    static var version: Int = 0

    enum IndexedFields: CodingKey, CaseIterable {
        case name, age
    }

    let name: String
    let age: Int

    var id: String {
        "\(name)\(age)"
    }
}

public enum ContentApp: AnyStateApp {
    public struct Helpers {
        let networkHelper: NetworkHelper
        let abiRepo: Repository<ABIItems>
        let personRepo: Repository<Person>
    }

    public static func initialState() -> State {
        State(buttonTapped: 0)
    }

    public enum Input {
        case buttonTapped
        case abiReceived(items: [ABIItems])
    }

    public struct State: Equatable, Codable {
        var buttonTapped: Int = 0
    }

    public enum Effect: Equatable {
        case buttonTappedSent
    }

    public static func handle(event: Input, with state: State) -> Next<State, Effect> {
        var state = state
        switch event {
        case .buttonTapped:
            return .with(.buttonTappedSent)
        case .abiReceived(let items):
            print("HERE: \(items.count)")
            state.buttonTapped += 1
            return .update(state: state)
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        switch effect {
        case .buttonTappedSent:
            let address = "0x65c816077c29b557bee980ae3cc2dce80204a0c5"
            _ = app.helpers.networkHelper.send(Etherscan.GetABI(address)) { result in
                switch result {
                case .success(var items):
                    items.indices.forEach{ items[$0].address = address } // HACK for id
                    app.dispatch(event: .abiReceived(items: items))
                    app.helpers.personRepo.dispatch(.add(items: [Person(name: "Lucas", age: state.buttonTapped)]))
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
}
