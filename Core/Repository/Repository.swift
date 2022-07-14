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

// We created a wrapper of the stateApp so we can have custom methods
// and other convenience variables
public class Repository<T: Equatable & Storable> {
    let stateApp: StateApp<RepositoryApp<T>>
    let modelBuilder: ModelBuilder<T>

    public func dispatch(_ event: RepositoryApp<T>.Input) {
        stateApp.dispatch(event)
    }

    // FIX: how to solve the getOne
    public func get(itemAt: Int) -> T {
        stateApp.dispatch(.readingItem(index: itemAt))
        let absolutePosition = itemAt - (stateApp.state.currentQuery?.page?.start ?? 0)
        return stateApp.state.cachedItems[absolutePosition]
    }

    init(freshStart: Bool = false) {
        guard let sqlStore = SQLStore<T>(freshStart: freshStart) else {
            fatalError("Can't create store for \(type(of: T.self))")
        }
        modelBuilder = ModelBuilder<T>()

        stateApp = StateApp<RepositoryApp<T>>(
            .init(
                dbExists: sqlStore.execute(modelBuilder.existsSQL())
            ),
            helpers: RepositoryApp<T>.Helpers(
                page: PageHelper(),
                sqlStore: sqlStore,
                modelBuilder: modelBuilder
            )
        )
    }
}

public enum RepositoryApp<T: Equatable & Storable>: AnyStateApp {
    public struct Helpers {
        let page: PageHelper
        let sqlStore: SQLStore<T>
        let modelBuilder: ModelBuilder<T>
    }

    public enum Input {
        case dbInitialized(items: [T])
        case add(items: [T])
        case setCache(items: [T])
        case setTotalCount(Int64)
        case readingItem(index: Int)
        case set(query: ListingQuery<T>)
    }

    public struct State: Equatable, Codable {
        var totalCount: Int64 = 0
        var cachedItems: [T] = []
        var currentIndex: Int = 0
        var currentQuery: ListingQuery<T>?
        var dbExists: Bool = false
    }

    public enum Effect: Equatable {
        case initialize(items: [T])
        case refreshItemsIfNeeded(around: Int)
        case reloadItems
        case add(items: [T])
    }

    public static func initialState() -> State {
        return State()
    }

    public static func handle(event: Input, with state: State) -> Next<State, Effect> {
        print("LUKEVENT: \(event)")
        switch event {
        case .add(let items):
            guard state.dbExists else {
                return .with(.initialize(items: items))
            }
            return .with(.add(items: items))
        case .dbInitialized(let items):
            var state = state
            state.dbExists = true
            return .init(state: state, effects: [.add(items: items)])
        case .readingItem(let index):
            return .with(.refreshItemsIfNeeded(around: index))
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
            return .init(state: state, effects: [.reloadItems])
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        switch effect {
        case .refreshItemsIfNeeded(let index):
            guard let currentQuery = state.currentQuery else { return }
            switch app.helpers.page.calculatePage(index: index, current: currentQuery.page ?? Page(start: 0)) {
            case .failure(let error):
                print(error)
            case .success(.suggested(let page)):
                print("LUK\(page.sql)")
                currentQuery.set(page: page)
                app.dispatch(event: .set(query: currentQuery))
                break
            case .success(.noChangeNeeded):
                break
            }
        case .reloadItems:
            guard let query = state.currentQuery,
                  let statement = app.helpers.sqlStore.prepare(query.query),
                  let items = try? app.helpers.modelBuilder.createObjects(stmt: statement)
            else { return }
            app.dispatch(event: .setCache(items: items))
        case .initialize(let items):
            // FIX: The reason we initialize the DB with values is that
            // reflection doesn't work with static types
            guard let firstItem = items.first else { return }
            [
                app.helpers.modelBuilder.createSQL(for: firstItem),
                app.helpers.modelBuilder.createFTSSQL(),
                app.helpers.modelBuilder.createRTreeSQL()
            ].forEach { queryString in
                app.helpers.sqlStore.execute(queryString)
            }

            guard app.helpers.sqlStore.execute(app.helpers.modelBuilder.existsSQL()) else {
                fatalError("DB non existent (should've been created or been already available)")
            }
            app.dispatch(event: .dbInitialized(items: items))
        case .add(let items):
            app.helpers.sqlStore.transaction(sqlStatements: items.compactMap { app.helpers.modelBuilder.insertSQL(for: $0) })
            guard let currentQuery = state.currentQuery,
                  let count: Int64 = app.helpers.sqlStore.scalar(using: currentQuery.countQuery)
            else {
                return
            }
            app.dispatch(event: .setTotalCount(count))
        }
    }
}
