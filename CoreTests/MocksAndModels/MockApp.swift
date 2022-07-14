//
//  MockApp.swift
//  Core
//
//  Created by 1Hyper Space on 4/9/21.
//

import XCTest
@testable import Core

public class MockApp<A: AnyStateApp> {
    private var initialState: A.State
    private var next: Next<A.State, A.Effect>?
    
    init(with state: A.State = A.initialState()) {
        self.initialState = state
    }
    
    @discardableResult
    public func given(event: A.Input) -> Self {
        self.next = A.handle(event: event, with: initialState)
        return self
    }
    
    @discardableResult
    public func assert(effects: A.Effect...) -> Self {
        XCTAssert(next?.effects == effects)
        return self
    }
    
    @discardableResult
    public func assert(state: A.State) -> Self {
        XCTAssert(next?.state == state)
        return self
    }
}
