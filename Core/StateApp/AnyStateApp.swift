//
//  AnyStateApp.swift
//  Core
//
//  Created by 1Hyper Space on 4/9/21.
//

import Foundation

public struct AnyDispatch<T, H> {
    private let closure: (T) -> Operation
    let helpers: H
    init(closure: @escaping (T) -> Operation, helpers: H) {
        self.closure = closure
        self.helpers = helpers
    }

    @discardableResult
    func dispatch(event: T) -> Operation {
        closure(event)
    }
}

public protocol AnyStateApp {
    associatedtype Helpers
    associatedtype Input
    associatedtype State: Codable & Equatable
    associatedtype Effect: Equatable
    static func initialState() -> State
    static func handle(event: Input, with state: State) -> Next<State, Effect>
    static func handle(effect: Effect, with state: State, on app: AnyDispatch<Self.Input, Self.Helpers>)
}

public class Next<State, Effect> {
    let state: State?
    let effects: [Effect]
    
    public init(state: State?, effects: [Effect]) {
        self.state = state
        self.effects = effects
    }
    
    static func update(state: State) -> Next<State, Effect> {
        return Next(state: state, effects: [])
    }
    
    static func with(_ effects: Effect...) -> Next<State, Effect> {
        return Next(state: nil, effects: effects)
    }
    
    static var none: Next<State, Effect> {
        return Next(state: nil, effects: [])
    }
}
