//
//  StateApp.swift
//  Core
//
//  Created by 1Hyper Space on 4/9/21.
//

import Foundation

public class StateApp<A: AnyStateApp>: ObservableObject {

    @Published private(set) var state: A.State

    private weak var delegate: StateApp?
    private let queue: DispatchQueue
    public let helpers: A.Helpers
    
    private lazy var eventOperationQueue: OperationQueue = {
      var queue = OperationQueue()
      queue.name = "Input Events Operation Queue"
      queue.maxConcurrentOperationCount = 1
      return queue
    }()
    
    private lazy var effectsOperationQueue: OperationQueue = {
      var queue = OperationQueue()
      queue.name = "Effects Operation Queue"
      queue.maxConcurrentOperationCount = 50
      return queue
    }()

    public init(_ state: A.State = A.initialState(), helpers: A.Helpers, queue: DispatchQueue = DispatchQueue.main) {
        self.state = state
        self.queue = queue
        self.helpers = helpers
    }

    @discardableResult
    public func dispatch(_ event: A.Input) -> Operation {
        let operation = EventOperation(event, delegate: self)
        eventOperationQueue.addOperation(operation)
        return operation
    }
    
    private func process(event: A.Input) -> Next<A.State, A.Effect> {
        let next = A.handle(event: event, with: state)

        if let newState = next.state {
            queue.async {
                self.state = newState
            }
        }

        // For next status, we can have the new one or the untouched one
        return Next(state: next.state ?? self.state, effects: next.effects)
    }
    
    private func process(effect: A.Effect, context: A.State) {
        let app = AnyDispatch(
            closure: { [weak self] (event: A.Input) in
                guard let self = self else { return Operation() }
                return self.dispatch(event)
            },
            helpers: self.helpers
        )
        A.handle(effect: effect, with: context, on: app)
    }
}

/*
 Extension for Operation. They handle threading.
 */
extension StateApp {
    class EventOperation: Operation {
        private let event: A.Input
        private weak var delegate: StateApp<A>?
        
        init(_ event: A.Input, delegate: StateApp<A>) {
            self.event = event
            self.delegate = delegate
        }
        
        override func main() {
            guard let delegate = delegate, isCancelled == false else {
                return
            }

            let next = delegate.process(event: event)
            
            guard isCancelled == false else {
                return
            }
            
            guard let nextState = next.state else {
                fatalError("At this point, it shouldn't be nil")
            }
            
            next.effects.map {
                EffectOperation($0, context: nextState, delegate: delegate)
            }.forEach {
                delegate.effectsOperationQueue.addOperation($0)
            }
        }
    }
    
    class EffectOperation: Operation {
        private let effect: A.Effect
        private let context: A.State
        private weak var delegate: StateApp<A>?

        init(_ effect: A.Effect, context: A.State, delegate: StateApp<A>) {
            self.effect = effect
            self.context = context
            self.delegate = delegate
        }
        
        override func main() {
            guard isCancelled == false else {
                return
            }
            
            delegate?.process(effect: effect, context: context)
        }
    }
}
