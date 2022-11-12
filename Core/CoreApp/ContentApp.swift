import Foundation
import UIKit

enum ContentApp: AnyStateApp {
    public struct Helpers {
        let networkHelper: NetworkHelper
        let movieRepo: Repository<Movie>
    }

    public static func initialState() -> State {
        State(buttonTapped: 0)
    }

    public enum Input {
        case checkForData
        case moviesParsed(items: [Movie])
    }

    public struct State: Equatable, Codable {
        var buttonTapped: Int = 0
    }

    public enum Effect: Equatable {
        case loadHistoricalEvents
        case saveToRepository(items: [Movie])
    }

    // TODO: Should we get access to the helpers here? otherwise you always
    // need to create a new effect to dispatch to another state machine
    public static func handle(event: Input, with state: State) -> Next<State, Effect> {
        var state = state
        switch event {
        case .checkForData:
            return .with(.loadHistoricalEvents)
        case .moviesParsed(let items):
            state.buttonTapped += 1
            return .init(state: state, effects: [.saveToRepository(items: items)])
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        switch effect {
        case .loadHistoricalEvents:
            let defaults = UserDefaults.standard

            defaults.removeObject(forKey: "dataLoaded")
            if defaults.bool(forKey: "dataLoaded") != true {
                defaults.set(true, forKey: "dataLoaded")
                defaults.synchronize()

                let asset = NSDataAsset(name: "movies", bundle: Bundle.main)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .secondsSince1970
                if let movies = try? decoder.decode([Movie].self, from: asset!.data) {
                    app.dispatch(event: .moviesParsed(items: movies))
                } else {
                    fatalError("Failed to read")
                }
            }
        case .saveToRepository(let items):
            app.helpers.movieRepo.dispatch(.add(items: items))
        }
    }
}
