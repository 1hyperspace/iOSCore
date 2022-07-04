//
//  SQLMachine.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation

public enum Constants {
    static let pageSize = 50
}

public enum Repository<T: Equatable & Storable>: AnyStateApp {
    public struct Helpers {
        let range: RangeHelper
        let sqlStore: SQLStore<T>
    }

    public enum Input {
        case dbInitialized
        case add(items: [T])
        case setCache(items: [T])
        case setTotalCount(Int)
        case readingItem(index: Int)
        case set(query: ListingQuery)
    }

    public struct State: Equatable, Codable {
        var pageSize: Int
        var totalCount: Int = 0
        var cachedItems: [T] = []
        var currentIndex: Int = 0
        var currentRange: Range<Int> = 0..<0
        var currentQuery: ListingQuery?
        var dbExists: Bool = false
    }

    public enum Effect: Equatable {
        case initialize(items: [T])
        case refreshItems(around: Int)
        case reloadItems
        case add(items: [T])
    }

    public static func initialState() -> State {
        return State(pageSize: Constants.pageSize)
    }

    public static func handle(event: Input, with state: State) -> Next<State, Effect> {
        switch event {
        case .add(let items):
            guard state.dbExists else {
                return .with(.initialize(items: items))
            }
            return .with(.add(items: items))
        case .dbInitialized:
            var state = state
            state.dbExists = true
            return .update(state: state)
        case .readingItem(let index):
            if !state.currentRange.contains(index) {
                return .with(.refreshItems(around: index))
            }
        case .set(query: let query):
            var state = state
            state.currentQuery = query
            return .init(state: state, effects: [.reloadItems])
        case .setCache(let items):
            var state = state
            state.cachedItems = items // TODO: do IDs diff for animations
            return .update(state: state)
        case .setTotalCount(let totalCount):
            var state = state
            state.totalCount = totalCount
            return .update(state: state)
        }
        
        return .none
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        switch effect {
        case .refreshItems(let index):
            switch app.helpers?.range.calculateRange(index: index, currentRange: state.currentRange) {
            case .failure(let error):
                print(error)
            case .success(.suggested(let range)):
                // drop old, add new
                state.currentQuery?.set(page: Page(start: range.startIndex, count: range.endIndex))
                break
            case .success(.noChangeNeeded), .none:
                break
            }
        case .reloadItems:
            guard let query = state.currentQuery, let items = app.helpers?.sqlStore.loadItems(query.queryString) else { return }
            app.dispatch(event: .setCache(items: items))
        case .initialize(let items):
            // The reason we initialize the DB with values is that
            // reflection doesn't work with static types
            guard let firstItem = items.first else { return }

            app.helpers?.sqlStore.initializeTables(for: firstItem)
            guard app.helpers!.sqlStore.exists() else {
                fatalError()
            }
            app.dispatch(event: .dbInitialized)
            app.dispatch(event: .add(items: items))
        case .add(let items):
            app.helpers?.sqlStore.add(items: items)
            app.dispatch(event: .setTotalCount(app.helpers?.sqlStore.count() ?? 0))
        }
    }

    public static func new(freshStart: Bool = false) -> StateApp<Self> {
        guard let sqlStore = SQLStore<T>(freshStart: freshStart) else {
            fatalError("Can't create store for \(type(of: T.self))")
        }

        return StateApp<Repository<T>>(
            State(
                pageSize: Constants.pageSize,
                dbExists: sqlStore.exists()
            ),
            helpers: Repository<T>.Helpers(
                range: RangeHelper(),
                sqlStore: sqlStore
            )
        )
    }

}
