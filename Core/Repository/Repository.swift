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

    public func get(itemAt: Int) -> T? {
        stateApp.dispatch(.readingItem(index: itemAt))
        let absolutePosition = itemAt - (stateApp.state.currentQuery?.page?.start ?? 0)

        if let item = stateApp.state.cachedItems[safe: absolutePosition] {
            return item
        }

        guard
            let currentQuery = stateApp.state.currentQuery,
            let statement = stateApp.helpers.sqlStore.prepare(
                currentQuery.set(page: Page(start: itemAt, count: 1)).query
            ),
            let item = try? stateApp.helpers.modelBuilder.createObjects(stmt: statement).first else {
                return nil
        }

        return item
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
        case setCache(items: [T], totalCount: Int)
        case setTotalCount(Int64)
        case readingItem(index: Int)
        case reloadItems
        case itemsReloaded
        case set(query: ListingQuery<T>)
    }

    public struct State: Equatable, Codable {
        var isLoadingItems = false
        var totalCount: Int = 0
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
        print("◦ EVENT: \(event)")
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
        case .reloadItems:
            switch state.isLoadingItems {
            case true:
                return .none
            case false:
                var state = state
                state.isLoadingItems = true
                return .with(.reloadItems)
            }
        case .itemsReloaded:
            var state = state
            state.isLoadingItems = false
            return .update(state: state)
        case .set(query: let query):
            var state = state
            state.currentQuery = query
            state.isLoadingItems = true
            return .init(state: state, effects: [.reloadItems])
        case .setCache(let items, let totalCount):
            var state = state
            state.cachedItems = items // TODO: do IDs diff for animations
            state.totalCount = totalCount
            return .update(state: state)
        case .setTotalCount(let totalCount):
            var state = state
            state.totalCount = Int(totalCount) // TODO: safely convert
            return .init(state: state, effects: [.reloadItems])
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        print("  ▉ Effect: \(effect)")
        switch effect {
        case .refreshItemsIfNeeded(let index):
            let currentQuery = state.currentQuery ?? app.helpers.modelBuilder.defaultQuery()
            switch app.helpers.page.calculatePage(index: index, current: currentQuery.page ?? Page(start: 0)) {
            case .failure(let error):
                print(error)
            case .success(.suggested(let page)):
                currentQuery.set(page: page)
                app.dispatch(event: .set(query: currentQuery))
                break
            case .success(.noChangeNeeded):
                break
            }
        case .reloadItems:
            let query = state.currentQuery ?? app.helpers.modelBuilder.defaultQuery()
            guard let statement = app.helpers.sqlStore.prepare(query.query),
                  let items = try? app.helpers.modelBuilder.createObjects(stmt: statement),
                  let count: Int64 = app.helpers.sqlStore.scalar(using: query.countQuery)
            else {
                return
            }
            app.dispatch(event: .setCache(items: items, totalCount: Int(count)))
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
            let currentQuery = state.currentQuery ?? app.helpers.modelBuilder.defaultQuery()
            guard let count: Int64 = app.helpers.sqlStore.scalar(using: currentQuery.countQuery)
            else {
                return
            }
            app.dispatch(event: .setTotalCount(count))
        }
    }
}
