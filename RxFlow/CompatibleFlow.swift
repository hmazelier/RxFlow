//
//  CompatibleFlow.swift
//  RxFlow
//
//  Created by Hadrien Mazelier on 07/06/2018.
//  Copyright © 2018 RxSwiftCommunity. All rights reserved.
//

import RxSwift
import RxCocoa

// This allows to integrate a flow in a different application architecture, while using the clarity of RxFlow
// Otherwise it relies on a Coordinator and a FlowCoordinator
public protocol CompatibleFlow: Flow {
    associatedtype StepperType: Stepper
    var stepper: StepperType { get }
    
    func start()
    func stop() -> Single<Void>
}

public extension CompatibleFlow {
    public func start() {
        stepper.steps
            .observeOn(MainScheduler.asyncInstance)
            .map { [unowned self] in return self.navigate(to: $0) }
            .subscribe(onNext: { [unowned self] (nextFlowItem) in
                func registerFlowItem(item: NextFlowItem) {
                    item.nextStepper.steps.takeUntil(item.nextPresentable.rxDismissed.asObservable())
                        .bind(to: self.stepper.step)
                        .disposed(by: self.disposeBag)
                }
                switch nextFlowItem {
                case .one(flowItem: let item):
                    registerFlowItem(item: item)
                case .multiple(flowItems: let items):
                    items.forEach(registerFlowItem)
                case .end(withStepForParentFlow: let step):
                    return self.stop()
                        .asObservable()
                        .withLatestFrom(Observable.just(step))
                        .bind(to: self.stepper.step)
                        .disposed(by: self.disposeBag)
                default: return
                }
            })
            .disposed(by: disposeBag)
    }
    
    
}
