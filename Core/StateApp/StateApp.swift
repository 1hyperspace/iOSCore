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
      queue.maxConcurrentOperationCount = 5
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
        queue.sync {
            let next = A.handle(event: event, with: state, and: helpers)
            if let newState = next.state {
                self.state = newState
            }
            // For next status, we can have the new one or the untouched one
            return Next(state: next.state ?? self.state, effects: next.effects)
        }
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
        public let event: A.Input
        private weak var delegate: StateApp<A>?
        
        init(_ event: A.Input, delegate: StateApp<A>) {
            self.event = event
            self.delegate = delegate
        }


        
        override func main() {
            guard let delegate = delegate, isCancelled == false else {
                print(" ❌ Cancel because of \(event) was cancelled")
                return
            }

            let next = delegate.process(event: event)
            
            guard isCancelled == false else {
                print(" ❌ Cancel because of \(event) was cancelled")
                return
            }
            
            guard let nextState = next.state else {
                fatalError("At this point, it shouldn't be nil")
            }
            
            next.effects.map {
                EffectOperation($0, context: nextState, delegate: delegate, eventOperation: self)
            }.forEach {
                delegate.effectsOperationQueue.addOperation($0)
            }
        }
    }
    
    class EffectOperation: Operation {
        private let effect: A.Effect
        private let context: A.State
        private weak var delegate: StateApp<A>?
        private var eventOperation: EventOperation

        init(_ effect: A.Effect, context: A.State, delegate: StateApp<A>, eventOperation: EventOperation) {
            self.effect = effect
            self.context = context
            self.delegate = delegate
            self.eventOperation = eventOperation
        }
        
        override func main() {
            // INFO: No one retains this operation, so this
            //       would never happen
            guard isCancelled == false else {
                print(" ❌ Cancel because of effect was cancelled")
                return
            }

            // The effect shouldn't take place if the event that triggered it
            // was cancelled
            guard eventOperation.isCancelled == false else {
                print("Cancelled because \(eventOperation.event) was cancelled")
                return
            }

            delegate?.process(effect: effect, context: context)
        }
    }
}
