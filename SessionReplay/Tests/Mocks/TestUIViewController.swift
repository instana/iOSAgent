//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import UIKit
import InstanaSessionReplay

/// A UIViewController designed for unit testing purposes
/// Contains various UI elements both visible and invisible for testing scenarios
class TestViewController: UIViewController {

    // MARK: - UI Elements

    /// Visible text field for user input
    let visibleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter text here"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isHidden = false
        return textField
    }()

    /// Invisible text field (hidden from view)
    let invisibleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Hidden text field"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isHidden = true
        return textField
    }()

    /// Text view for multi-line text input
    let textView: UITextView = {
        let textView = UITextView()
        textView.text = "Sample text view content"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5.0
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    /// Label for displaying text
    let label: UILabel = {
        let label = UILabel()
        label.text = "Test Label"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Image view for displaying images
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    /// Button for user interaction
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test Button", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Slider for value selection
    let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    /// Stepper for incremental value changes
    let stepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 10
        stepper.value = 5
        stepper.translatesAutoresizingMaskIntoConstraints = false
        return stepper
    }()

    /// Switch for toggle functionality
    let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        InstanaSessionReplay.maskView(label)
        InstanaSessionReplay.maskView(imageView)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        InstanaSessionReplay.unmaskView(label)
        InstanaSessionReplay.unmaskView(imageView)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        // Add all subviews
        view.addSubview(visibleTextField)
        view.addSubview(invisibleTextField)
        view.addSubview(textView)
        view.addSubview(label)
        view.addSubview(imageView)
        view.addSubview(button)
        view.addSubview(slider)
        view.addSubview(stepper)
        view.addSubview(switchControl)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Visible TextField
            visibleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            visibleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            visibleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            visibleTextField.heightAnchor.constraint(equalToConstant: 40),

            // Invisible TextField (positioned but hidden)
            invisibleTextField.topAnchor.constraint(equalTo: visibleTextField.bottomAnchor, constant: 10),
            invisibleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            invisibleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            invisibleTextField.heightAnchor.constraint(equalToConstant: 40),

            // TextView
            textView.topAnchor.constraint(equalTo: invisibleTextField.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 100),

            // Label
            label.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.heightAnchor.constraint(equalToConstant: 30),

            // ImageView
            imageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),

            // Button
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.heightAnchor.constraint(equalToConstant: 44),

            // Slider
            slider.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Stepper
            stepper.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            stepper.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Switch
            switchControl.topAnchor.constraint(equalTo: stepper.bottomAnchor, constant: 20),
            switchControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
