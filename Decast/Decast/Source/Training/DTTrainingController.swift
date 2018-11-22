//
//  DTTrainingController.swift
//  Decast
//
//  Created by David Moore on 11/21/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RemoteKit

protocol DTTrainingControllerDelegate: NSObjectProtocol {
    func trainingController(_ trainingController: DTTrainingController, didFinishTrainingRemote remote: RKRemote)
    func trainingControllerDidDismiss(_ trainingController: DTTrainingController)
}

class DTTrainingController: NSObject {
    
    // MARK: - Properties
    
    private var onboardingController: SFOnboardingController!
    
    let session: RKSession
    
    var parentViewController: UIViewController
    
    private var trainingSession: RKTrainingSession?
    
    weak var delegate: DTTrainingControllerDelegate?
    
    // MARK: - Initialization
    
    init(parent viewController: UIViewController, session: RKSession) {
        parentViewController = viewController
        self.session = session
        super.init()
        onboardingController = SFOnboardingController(stages: [createWelcomeStage(), createRemoteNameStage(), createStartStage()])
    }
    
    deinit {
        if let trainingSession = self.trainingSession {
            session.suspend(trainingSession)
        }
    }
    
    // MARK: - Presentation
    
    func present(animated: Bool, completion: (() -> Void)? = nil) {
        parentViewController.present(onboardingController, animated: animated, completion: completion)
    }
}

extension DTTrainingController {
    
    private func createWelcomeStage() -> SFOnboardingStage {
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Train a Remote", comment: "")),
                                              detailLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Training a remote involves a number of steps and a fair amount of time. Be sure to ensure your remote is not already trained to avoid wasting time. Make sure you are near your Decast device before you start training.", comment: "")),
                                              separatorIsHidden: true)
        
        let secondaryControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Cancel", comment: ""),
                                                 actions: [.dismissOnboardingController(.touchUpInside)])
        let primaryControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Continue", comment: ""),
                                                 actions: [.pushNextStage(.touchUpInside)])
        
        let stage = SFOnboardingStage(cards: [titleCard], primaryControl: primaryControl, secondaryControl: secondaryControl,
                                      leadingControl: nil, trailingControl: nil, accessoryLabel: nil, cellSelected: nil)
        
        return stage
    }
    
    private func createRemoteNameStage() -> SFOnboardingStage {
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Name Remote", comment: "")),
                                              detailLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Enter the name of the remote that you're training.", comment: "")),
                                              separatorIsHidden: false)
        
        let textField = SFOnboardingTextField(localizedPlaceholder: NSLocalizedString("Name of remote", comment: ""))
        let textFieldCard = SFOnboardingTextFieldCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Name", comment: "")),
                                                      textField: textField)
        
        // Make a new trailing control.
        let trailingControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Next", comment: ""))
        
        // Disable the trailing control to begin.
        trailingControl.keyedValues = [#keyPath(UIControl.isEnabled): false]
        
        // Create a closure that enables/disables the trailing button for text input validation.
        let validateTextInput: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            // Retrieve the appropriate cells.
            let cell = controller!.cell(for: textFieldCard) as! SFOnboardingTextFieldCardCell
            
            // Input validation for this application is limited, as third-party providers may have varying credential requirements.
            // Determine if the text is valid.
            let isValid = !(cell.textField.text ?? "").isEmpty
            
            // Enable/disable the trailing button according to the validation status.
            controller?.trailingButton.isEnabled = isValid
        }
        
        let createTrainingSession: SFOnboardingControl.CommunicationClosure = { controller, sender, callback in
            let cell = controller!.cell(for: textFieldCard) as! SFOnboardingTextFieldCardCell
            guard let text = cell.textField.text else { return }
            
            let remote = RKRemote(localizedTitle: text)
            self.trainingSession = self.session.newTrainingSession(for: remote)
            self.trainingSession?.delegate = self
            
            callback([.pushNextStage([])])
        }
        
        
        // Assign arbitrary action.
        textField.actions = [.enableUserInteraction(.editingChanged),
                             .closure(.editingChanged, validateTextInput),
                             .closure(.editingDidEndOnExit, createTrainingSession)]
        trailingControl.actions = [.closure(.touchUpInside, createTrainingSession)]
        
        let leadingControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Back", comment: ""),
                                                 actions: [.popStage(.touchUpInside)])
        
        let stage = SFOnboardingStage(cards: [titleCard, textFieldCard], primaryControl: nil, secondaryControl: nil, leadingControl: leadingControl, trailingControl: trailingControl, accessoryLabel: nil, cellSelected: nil)
        
        return stage
    }
    
    private func createStartStage() -> SFOnboardingStage {
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Start Training", comment: "")), detailLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Have the remote ready for training and stand next to your Decast device. Tap Start when you're ready to begin training the remote.", comment: "")), image: nil, isLargeTitle: true, separatorIsHidden: true)
        
        let startTrainingSession: SFOnboardingControl.CommunicationClosure = { controller, sender, callback in
            controller?.primaryButton.isEnabled = false
            controller?.leadingButton.isEnabled = false
            
            guard let trainingSession = self.trainingSession else { return }
            self.session.start(trainingSession)
        }
        
        let primaryControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Start", comment: ""),
                                                 actions: [.disableUserInteraction(.touchUpInside),
                                                           .startActivityIndicator(.touchUpInside),
                                                           .closure(.touchUpInside, startTrainingSession)])
        let leadingControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Back", comment: ""),
                                                 actions: [.popStage(.touchUpInside)])
        
        let stage = SFOnboardingStage(cards: [titleCard], primaryControl: primaryControl, secondaryControl: nil, leadingControl: leadingControl, trailingControl: nil, accessoryLabel: nil, cellSelected: nil)
        
        return stage
    }
    
    private func createNewCommandStage() -> SFOnboardingStage {
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("New Command", comment: "")),
                                              detailLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Type the name of the command you want to train.", comment: "")),
                                              separatorIsHidden: false)
        
        let textField = SFOnboardingTextField(localizedPlaceholder: NSLocalizedString("Command name", comment: ""))
        let textFieldCard = SFOnboardingTextFieldCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Name", comment: "")),
                                                      textField: textField)
        
        let primaryControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Create Command", comment: ""))
        primaryControl.keyedValues = [#keyPath(UIControl.isEnabled): false]
        
        // Create a closure that enables/disables the trailing button for text input validation.
        let validateTextInput: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            // Retrieve the appropriate cells.
            let cell = controller!.cell(for: textFieldCard) as! SFOnboardingTextFieldCardCell
            
            // Input validation for this application is limited, as third-party providers may have varying credential requirements.
            // Determine if the text is valid.
            let isValid = !(cell.textField.text ?? "").isEmpty
            
            // Enable/disable the trailing button according to the validation status.
            controller?.primaryButton.isEnabled = isValid
        }
        
        let learnCommand: SFOnboardingControl.CommunicationClosure = { controller, sender, callback in
            controller?.leadingButton.isEnabled = false
            controller?.primaryButton.isEnabled = false
            
            let cell = controller!.cell(for: textFieldCard) as! SFOnboardingTextFieldCardCell
            guard let text = cell.textField.text else { return }
            
            self.trainingSession?.createCommand(withLocalizedTitle: text)
            
            callback([.pushNextStage([])])
        }
        
        primaryControl.actions = [.startActivityIndicator(.touchUpInside),
                                  .disableUserInteraction(.touchUpInside),
                                  .closure(.touchUpInside, learnCommand)]
        
        let suspendTrainingSession: SFOnboardingControl.CommunicationClosure = { controller, sender, callback in
            // FIXME: Should return after the suspension, but for now this is okay.
            self.delegate?.trainingController(self, didFinishTrainingRemote: self.trainingSession!.remote)
            
            self.session.suspend(self.trainingSession!)
            self.trainingSession = nil
            
            callback([.dismissOnboardingController([])])
            self.delegate?.trainingControllerDidDismiss(self)
        }
        
        // Assign arbitrary action.
        textField.actions = [.closure(.editingChanged, validateTextInput),
                             .closure(.editingDidEndOnExit, learnCommand),
                             .disableUserInteraction(.editingDidEndOnExit),
                             .startActivityIndicator(.editingDidEndOnExit)]
        
        let leadingControl = SFOnboardingControl(localizedTitle: NSLocalizedString("Done", comment: ""),
                                                 actions: [.disableUserInteraction(.touchUpInside),
                                                           .closure(.touchUpInside, suspendTrainingSession)])
        
        let stage = SFOnboardingStage(cards: [titleCard, textFieldCard], primaryControl: primaryControl, secondaryControl: nil, leadingControl: leadingControl, trailingControl: nil, accessoryLabel: nil, cellSelected: nil)
        
        return stage
    }
    
    /*private func createInclusiveArbitraryInputStage() -> SFOnboardingStage {
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Random Input", comment: "")), detailLabel: SFOnboardingLabel(localizedTitle: NSLocalizedString("Repeatedly hold down random keys on the remote, while pointing at the Decast device. Try to hold each key for about 1 second then switch to another one.", comment: "")), image: nil, isLargeTitle: false, separatorIsHidden: true)
        
        let stage = SFOnboardingStage(cards: [titleCard], primaryControl: nil, secondaryControl: nil, leadingControl: nil, trailingControl: nil, accessoryLabel: nil, cellSelected: nil)
        
        return stage
    }*/
}

extension DTTrainingController: RKTrainingSessionDelegate {
    
    func trainingSessionDidBegin(_ trainingSession: RKTrainingSession) {
        DispatchQueue.main.async {
            self.onboardingController.push(self.createNewCommandStage(), animated: true)
        }
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didCreateCommand command: RKCommand) {
        // Start learning the command.
        trainingSession.learn(command)
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didFailToCreateCommandWithError error: Error) {
        // FIXME: Do not ship like this.
        onboardingController.dismiss(animated: true)
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didFailWithError error: Error) {
        // FIXME: Do not ship like this.
        onboardingController.dismiss(animated: true)
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, willLearnCommand command: RKCommand) {
        
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didLearnCommand command: RKCommand) {
        DispatchQueue.main.async {
            if let viewController = self.onboardingController.topViewController as? SFOnboardingStageViewController {
                let titleCell = viewController.cell(for: viewController.stage.cards.first!) as? SFOnboardingTitleCardCell
                titleCell?.titleLabel.text = NSLocalizedString("Command Learned", comment: "")
                titleCell?.detailLabel.text = NSLocalizedString("Decast has learned the command.", comment: "")
            }
            
            self.onboardingController.push(self.createNewCommandStage(), animated: true)
        }
    }
    
    func trainingSessionDidRequestInclusiveArbitraryInput(_ trainingSession: RKTrainingSession) {
        DispatchQueue.main.async {
            if let viewController = self.onboardingController.topViewController as? SFOnboardingStageViewController {
                let titleCell = viewController.cell(for: viewController.stage.cards.first!) as? SFOnboardingTitleCardCell
                titleCell?.titleLabel.text = NSLocalizedString("Random Input", comment: "")
                titleCell?.detailLabel.text = NSLocalizedString("Repeatedly hold down random keys on the remote, while pointing at the Decast device. Try to hold each key for about 1 second then switch to another one.", comment: "")
            }
        }
    }
    
    func trainingSession(_ trainingSession: RKTrainingSession, didRequestInputForCommand command: RKCommand) {
        DispatchQueue.main.async {
            if let viewController = self.onboardingController.topViewController as? SFOnboardingStageViewController {
                let titleCell = viewController.cell(for: viewController.stage.cards.first!) as? SFOnboardingTitleCardCell
                titleCell?.titleLabel.text = NSLocalizedString("Command Input", comment: "")
                titleCell?.detailLabel.text = NSLocalizedString("Hold down the command while pointing at the Decast device.", comment: "")
            }
        }
    }
    
    func trainingSessionDidRequestExclusiveArbitraryInput(_ trainingSession: RKTrainingSession) {
        
    }
}
