//
//  RKAuthenticationController.swift
//  RemoteKit
//
//  Created by David Moore on 11/17/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

import SFKit
import RFCore
import AWSCognitoIdentityProvider

protocol RKAuthenticationControllerDelegate: NSObjectProtocol {
    
    func authenticationController(_ authenticationController: RKAuthenticationController,
                                  present viewController: UIViewController)
}

final class RKAuthenticationController: NSObject {

    // MARK: - Properties
    
    /// Delegate that is used for authentication.
    weak var delegate: RKAuthenticationControllerDelegate?
    
    /// Onboarding controller to use for authentication.
    private var onboardingController: SFOnboardingController
    
    /// Container that is used for authentication-related purposes.
    var container: RFContainer
    
    // MARK: - Initialization
    
    init(container: RFContainer) {
        self.container = container
        
        // Configure the onboarding controller.
        onboardingController = SFOnboardingController()
        onboardingController.modalPresentationStyle = .formSheet
    }
    
    // MARK: - Helper Methods
    
    /// Presents the onboarding controller as a modal.
    private func presentOnboardingController() {
        delegate?.authenticationController(self, present: onboardingController)
    }
    
    /// Dismisses the onboarding controller from modal.
    private func dismissOnboardingController() {
        onboardingController.dismiss(animated: true)
    }
}

// MARK: - Cognito Identity Interactive Authentication Delegate

extension RKAuthenticationController: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        DispatchQueue.main.async { self.presentOnboardingController() }
        return self
    }
    
    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
        DispatchQueue.main.async { self.presentOnboardingController() }
        return self
    }
}

// MARK: - Cognito Identity Password Authentication

extension RKAuthenticationController: AWSCognitoIdentityPasswordAuthentication {
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        // Define localized strings.
        let titleCardTitle = NSLocalizedString("Remote Core", comment: "Name of the company")
        let titleCardDescription = NSLocalizedString("", comment: "Description that tells the user what they are doing")
        let requiredPlaceholder = NSLocalizedString("Required", comment: "Placeholder for a text field stating that it must be filled in")
        let usernameCardTitle = NSLocalizedString("Username", comment: "Label beside a text field that tells the user what to enter in the field")
        let passwordCardTitle = NSLocalizedString("Password", comment: "Label beside a text field that tells the user what to enter in the field")
        let trailingTitle = NSLocalizedString("Next", comment: "Title of button that moves to the next page of the onboarding process")
        
        // Create the text fields.
        let usernameTextField = SFOnboardingTextField(localizedPlaceholder: requiredPlaceholder)
        usernameTextField.returnKeyType = .next
        usernameTextField.keyboardType = .emailAddress
        if #available(iOS 11.0, *) { usernameTextField.textContentType = .username }
        
        // Pre-populate the username field, if it is known.
        usernameTextField.keyedValues = [#keyPath(UITextField.text): authenticationInput.lastKnownUsername as Any]
        
        let passwordTextField = SFOnboardingTextField(localizedPlaceholder: requiredPlaceholder)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = .done
        passwordTextField.keyboardType = .default
        if #available(iOS 11.0, *) { passwordTextField.textContentType = .password }
        
        // Create new cards using previously defined objects and values.
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: titleCardTitle),
                                              detailLabel: SFOnboardingLabel(localizedTitle: titleCardDescription),
                                              separatorIsHidden: false)
        let usernameCard = SFOnboardingTextFieldCard(titleLabel: SFOnboardingLabel(localizedTitle: usernameCardTitle),
                                                     textField: usernameTextField)
        let passwordCard = SFOnboardingTextFieldCard(titleLabel: SFOnboardingLabel(localizedTitle: passwordCardTitle),
                                                     textField: passwordTextField)
        
        // Make a new trailing control.
        let trailingControl = SFOnboardingControl(localizedTitle: trailingTitle)
        
        // Disable the trailing control to begin.
        trailingControl.keyedValues = [#keyPath(UIControl.isEnabled): false]
        
        // Create a closure that enables/disables the trailing button for text input validation.
        let validateTextInput: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            // Retrieve the appropriate cells.
            let usernameCell = controller!.cell(for: usernameCard) as! SFOnboardingTextFieldCardCell
            let passwordCell = controller!.cell(for: passwordCard) as! SFOnboardingTextFieldCardCell
            
            // Input validation for this application is limited, as third-party providers may have varying credential requirements.
            // Determine if the text is valid.
            let isValid = !(usernameCell.textField.text ?? "").isEmpty && !(passwordCell.textField.text ?? "").isEmpty
            
            // Enable/disable the trailing button according to the validation status.
            controller?.trailingButton.isEnabled = isValid
        }
        
        // Define a closure that will select the password text field after the username text field's return key is hit.
        let selectPasswordField: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            // Retrieve the password cell.
            let passwordCell = controller!.cell(for: passwordCard) as! SFOnboardingTextFieldCardCell
            
            // Select the password cell to become first responder.
            passwordCell.textField.becomeFirstResponder()
        }
        
        // Create a communication closure for processing credentials.
        let processCredentials: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            guard controller!.trailingButton.isEnabled else { return }
            
            // Retrieve the appropriate cells.
            let usernameCell = controller!.cell(for: usernameCard) as! SFOnboardingTextFieldCardCell
            let passwordCell = controller!.cell(for: passwordCard) as! SFOnboardingTextFieldCardCell
            
            // Unwrap the text values from the cells.
            guard let username = usernameCell.textField.text,
                let password = passwordCell.textField.text else {
                    handler([.enableUserInteraction([])])
                    return
            }
            
            // Create an account.
            let account = AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password)
            
            // Provide the account as the result.
            passwordAuthenticationCompletionSource.set(result: account)
        }
        
        // Assign arbitrary action.
        usernameTextField.actions = [.enableUserInteraction(.editingChanged),
                                     .closure(.editingChanged, validateTextInput),
                                     .closure(.editingDidEndOnExit, selectPasswordField)]
        passwordTextField.actions = [.closure(.editingChanged, validateTextInput),
                                     .disableUserInteraction(.editingDidEndOnExit),
                                     .startActivityIndicator(.editingDidEndOnExit),
                                     .closure(.editingDidEndOnExit, processCredentials)]
        trailingControl.actions = [.disableUserInteraction(.touchUpInside),
                                   .startActivityIndicator(.touchUpInside),
                                   .closure(.touchUpInside, processCredentials)]
        
        // Create a stage for the title card.
        let loginStage = SFOnboardingStage(cards: [titleCard, usernameCard, passwordCard], primaryControl: nil,
                                      trailingControl: trailingControl)
        
        let pushLoginStage: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            controller?.onboardingController?.push(loginStage, animated: true)
        }
        
        let a = SFOnboardingControl(localizedTitle: "Create an Account", actions: [.closure(.touchUpInside, pushLoginStage)])
        let b = SFOnboardingControl(localizedTitle: "Sign In", actions: [.closure(.touchUpInside, pushLoginStage)])
        
        let t = SFOnboardingStage(cards: [titleCard], primaryControl: a, secondaryControl: b, leadingControl: nil,
                                  trailingControl: nil, accessoryLabel: nil, cellSelected: nil)
        
        // Present the stage.
        DispatchQueue.main.async { self.onboardingController.push(t, animated: true) }
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        if error == nil {
            dismissOnboardingController()
        }
    }
}

// MARK: - Cognito Identity New Password Required

extension RKAuthenticationController: AWSCognitoIdentityNewPasswordRequired {
    
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput, newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        let titleCardTitle = NSLocalizedString("New Password Required", comment: "Title stating that a new password is required for the user.")
        let titleCardDescription = NSLocalizedString("Your password has expired, please enter a new one.", comment: "Description telling the user that they need a new password.")
        let trailingTitle = NSLocalizedString("Next", comment: "Title of button that moves to the next page of the onboarding process")
        let requiredPlaceholder = NSLocalizedString("Required", comment: "Placeholder for a text field stating that it must be filled in")
        let optionalPlaceholder = NSLocalizedString("Optional", comment: "Placeholder for a text field indicating that its value does not need to be filled in")
        let passwordTitle = NSLocalizedString("New Password", comment: "Label beside a text field that tells the user what to enter in the field")
        let confirmPasswordTitle = NSLocalizedString("Confirm", comment: "Label beside a text field that tells the user what to enter in the field")
        let accessoryTitle = NSLocalizedString("", comment: "Description of the new password being entered and how privacy is handled.")
        
        // Declare a Field tuple-type.
        typealias Field = (localizedTitle: String, isRequired: Bool, isSecureTextEntry: Bool, returnKeyType: UIReturnKeyType, keyboardType: UIKeyboardType)
        
        let fields: [Field] = [(passwordTitle, true, true, .next, .default),
                               (confirmPasswordTitle, true, true, .done, .default)]
        
        let cards = fields.map { aField -> SFOnboardingTextFieldCard in
            let placeholderString = aField.isRequired ? requiredPlaceholder : optionalPlaceholder
            
            // Create the text field.
            let aTextField = SFOnboardingTextField(localizedPlaceholder: placeholderString)
            aTextField.isSecureTextEntry = aField.isSecureTextEntry
            aTextField.returnKeyType = aField.returnKeyType
            aTextField.keyboardType = aField.keyboardType
            
            // Use the text field to create a card.
            let aCard = SFOnboardingTextFieldCard(titleLabel: SFOnboardingLabel(localizedTitle: aField.localizedTitle),
                                                  textField: aTextField)
            
            return aCard
        }
        
        // Create new cards using previously defined objects and values.
        let titleCard = SFOnboardingTitleCard(titleLabel: SFOnboardingLabel(localizedTitle: titleCardTitle),
                                              detailLabel: SFOnboardingLabel(localizedTitle: titleCardDescription),
                                              separatorIsHidden: false)
        
        // Make a new trailing control.
        let trailingControl = SFOnboardingControl(localizedTitle: trailingTitle)
        
        // Disable the trailing control to begin.
        trailingControl.keyedValues = [#keyPath(UIControl.isEnabled): false]
        
        // Create a closure that enables/disables the trailing button for text input validation.
        let validateTextInput: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            let isNotEmpty = cards.reduce(true) { isValid, card -> Bool in
                if isValid {
                    // Retrieve the cell and check if it is empty.
                    let cell = controller!.cell(for: card) as! SFOnboardingTextFieldCardCell
                    return !(cell.textField.text ?? "").isEmpty
                } else { return false }
            }
            
            if isNotEmpty {
                // Retrieve the two password cells.
                let passwordCells = cards[(cards.count - 2)..<cards.count].map { controller!.cell(for: $0) as! SFOnboardingTextFieldCardCell }
                
                // Enable/disable the trailing button according to the validation status.
                controller?.trailingButton.isEnabled = passwordCells.first!.textField.text! == passwordCells.last!.textField.text!
            } else {
                controller?.trailingButton.isEnabled = false
            }
        }
        
        let completeTask: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            guard controller!.trailingButton.isEnabled else { return }
            
            // Display some UI that indicates a network operation is ongoing.
            handler([.disableUserInteraction([]), .startActivityIndicator([])])
            
            // Map the cell values.
            let cellValues = cards.map { (controller!.cell(for: $0) as! SFOnboardingTextFieldCardCell).textField.text! }
            
            // Create a new password details object.
            let details = AWSCognitoIdentityNewPasswordRequiredDetails(proposedPassword: cellValues[0],
                                                                       userAttributes: [:])
            
            // Provide the details.
            newPasswordRequiredCompletionSource.set(result: details)
        }
        
        let selectNextField: SFOnboardingControl.CommunicationClosure = { controller, sender, handler in
            // Retrieve the current cell by using the sender.
            let cell = (sender as! UITextField).superview?.superview as! SFOnboardingTextFieldCardCell
            
            // Determine the next cell index path.
            let indexPath = controller!.tableView.indexPath(for: cell)!
            let nextIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            
            // Validate nextIndexPath and determine if the next cell is an appropriate class.
            if nextIndexPath.row < controller!.tableView.numberOfRows(inSection: nextIndexPath.section),
                let nextCell = controller!.tableView.cellForRow(at: nextIndexPath) as? SFOnboardingTextFieldCardCell {
                nextCell.textField.becomeFirstResponder()
            } else {
                // Complete the task.
                completeTask(controller, sender, handler)
            }
        }
        
        // Assign basic actions to each card.
        for card in cards {
            card.textField.actions = [.closure(.editingChanged, validateTextInput),
                                      .closure(.editingDidEndOnExit, selectNextField)]
        }
        
        // Complete the task when the user goes to continue.
        trailingControl.actions = [.closure(.touchUpInside, completeTask)]
        
        // Create a stage for the title card.
        let stage = SFOnboardingStage(cards: [titleCard] + cards, trailingControl: trailingControl,
                                      accessoryLabel: SFOnboardingLabel(localizedTitle: accessoryTitle))
        
        // Present the stage.
        DispatchQueue.main.async { self.onboardingController.push(stage, animated: true) }
    }
    
    func didCompleteNewPasswordStepWithError(_ error: Error?) {
        if error == nil {
            dismissOnboardingController()
        }
    }
}
