//
//  SQLMachine.swift
//  Core
//
//  Created by 1Hyper Space on 4/12/21.
//

import Foundation

// We created a wrapper of the stateApp so we can have custom methods
// and other convenience variables
public class Repository<T: Equatable & Storable> {
    let stateApp: StateApp<RepositoryApp<T>>
    let modelBuilder: ModelBuilder<T>
    var previousOperation: Operation? = nil

    public func dispatch(_ event: RepositoryApp<T>.Input) -> Operation {
        stateApp.dispatch(event)
    }

    public func get(itemAt index: Int) -> T? {
        previousOperation?.cancel()
        previousOperation = stateApp.dispatch(.readingItem(index: index))

        guard stateApp.state.currentQuery?.page?.contains(index: index) == true else {
            return nil
        }

        let absolutePosition = index - (stateApp.state.currentQuery?.page?.start ?? 0)

        return stateApp.state.cachedItems[safe: absolutePosition]
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
        case set(query: Query<T>)
    }

    public struct EphemeralState {
        var newItems: [String]
    }

    public struct State: Equatable, Codable {
        var isLoadingItems = false
        var totalCount: Int = 0
        var cachedItems: [T] = []
        var currentIndex: Int = 0
        var currentQuery: Query<T>?
        var dbExists: Bool = false
    }

    public enum Effect: Equatable {
        case initialize(items: [T])
        case getCache
        case addToDB(items: [T])
    }

    public static func initialState() -> State {
        return State()
    }

    public static func handle(event: Input, with state: State, and helpers: Helpers) -> Next<State, Effect> {
        print("◦ EVENT: \(String(describing: event).prefix(100))")
        switch event {
        case .add(let items):
            guard state.dbExists else {
                return .with(.initialize(items: items))
            }
            return .with(.addToDB(items: items))
        case .dbInitialized(let items):
            var state = state
            state.dbExists = true
            return .init(state: state, effects: [.addToDB(items: items)])
        case .readingItem(let index):
            // Reading item does not update state, otherwise it would
            // loop forever, since it reloads the table
            let currentPage = state.currentQuery?.page ?? Page(start: 0)
            switch helpers.page.calculatePage(index: index, current: currentPage) {
            case .failure(let error):
                print(error)
            case .success(.suggested(let page)):
                print("  📘 Current Page: \(currentPage) - index \(index) - Suggested Page: \(page)")
                // THIS works because it's by reference :nervous laugh:
                _ = state.currentQuery?.set(page: page)
                return .with(.getCache)
            case .success(.noChangeNeeded):
                print("  📘 No change needed")
                break
            }
            return .none
        case .reloadItems:
            switch state.isLoadingItems {
            case true:
                return .none
            case false:
                var state = state
                state.isLoadingItems = true
                return .init(state: state, effects: [.getCache])
            }
        case .itemsReloaded:
            var state = state
            state.isLoadingItems = false
            return .update(state: state)
        case .set(query: let query):
            var state = state
            state.currentQuery = query
            state.isLoadingItems = true
            if let count: Int64 = helpers.sqlStore.scalar(using: query.sqlCount) {
                state.totalCount = Int(count)
            }

            return .init(state: state, effects: [.getCache])
        case .setCache(let items, let totalCount):
            var state = state
            state.cachedItems = items // TODO: do IDs diff for animations
            state.totalCount = totalCount
            return .update(state: state)
        case .setTotalCount(let totalCount):
            var state = state
            state.totalCount = Int(totalCount) // TODO: safely convert
            return .init(state: state, effects: [.getCache])
        }
    }

    public static func handle(effect: Effect, with state: State, on app: AnyDispatch<Input, Helpers>) {
        print("  ▉ Effect: \(String(describing: effect).prefix(100))")
        switch effect {
        case .getCache:
            let query = state.currentQuery ?? app.helpers.modelBuilder.defaultQuery()
            guard let statement = app.helpers.sqlStore.prepare(query.sql(with: nil)),
                  let items = try? app.helpers.modelBuilder.createObjects(stmt: statement),
                  let count: Int64 = app.helpers.sqlStore.scalar(using: query.sqlCount)
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
                app.helpers.modelBuilder.createFTSSQL(for: firstItem),
            ].forEach { queryString in
                app.helpers.sqlStore.execute(queryString)
            }

            guard app.helpers.sqlStore.execute(app.helpers.modelBuilder.existsSQL()) else {
                fatalError("DB non existent (should've been created or been already available)")
            }
            app.dispatch(event: .dbInitialized(items: items))
        case .addToDB(let items):
            app.helpers.sqlStore.transaction(sqlStatements: items.flatMap {
                app.helpers.modelBuilder.addItem($0)
            })
            let currentQuery = state.currentQuery ?? app.helpers.modelBuilder.defaultQuery()
            guard let count: Int64 = app.helpers.sqlStore.scalar(using: currentQuery.sqlCount)
            else {
                return
            }
            app.dispatch(event: .setTotalCount(count))
        }
    }
}
