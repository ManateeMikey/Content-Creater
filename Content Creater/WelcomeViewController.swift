//
//  ViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-07-27.
//
import UIKit
import CoreData
import Photos
//import RevenueCat


class WelcomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var displayView: UITableView!
    var randomEntries: [JournalEntry] = []
    var currentRandomEntryIndex = 0
    var displayRandomEntryWorkItem: DispatchWorkItem?
    var confettiLayer1: CAEmitterLayer!
    var confettiLayer2: CAEmitterLayer!
    var confettiLayer3: CAEmitterLayer!
    var imagePickerCompletion: ((String?) -> Void)?
    let CDcontext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var items: [JournalEntry] = []
    
    private let entryCellIdentifier = "EntryCell"
    private let textColor = UIColor(red: 51/255.0, green: 102/255.0, blue: 153/255.0, alpha: 1.0)
    
    // Add a property to store the selected photo
    var selectedPhoto: UIImage?
    
    // Add a property to store the local identifier of the selected photo, defaulting to nil
    var selectedPhotoLocalIdentifier: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupTableView()
        //        setupBookImageView()
        setupConfettiAnimation()
//        examineCoreDataInfo()
        fetchRandomEntry()
        checkAndSetDefaultBackgroundPhoto()
        
        // Set the table view background color with 30% opacity
        displayView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        // Apply round corners and opacity to the table view
        displayView.layer.cornerRadius = 20
        displayView.layer.masksToBounds = true
        displayView.layer.opacity = 0.8
    }
    
    func checkAndSetDefaultBackgroundPhoto() {
        do {
            let fetchRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
            let allEntries = try CDcontext.fetch(fetchRequest)
            if allEntries.isEmpty {
                defaultBackgroundPhoto()
            }
        } catch {
            print("Error fetching JournalEntries:", error.localizedDescription)
        }
    }
    
    func examineCoreDataInfo() {
        do {
            let fetchRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
            let allEntries = try CDcontext.fetch(fetchRequest)
            
            for entry in allEntries {
                print("Journal Entry:")
                print("ID: \(entry.objectID)")
                print("Body: \(entry.body ?? "No body")")
                print("Timestamp: \(entry.timestamp ?? Date())")
                print("Photo Local Identifier: \(entry.photoLocalIdentifier ?? "No photo identifier")")
                // Add more properties if needed
                
                // Fault the entry into memory if it is a fault
                if entry.isFault {
                    CDcontext.refresh(entry, mergeChanges: true)
                }
                
                // Access more properties as needed
                
                print("----------")
            }
        } catch {
            print("Error fetching JournalEntries:", error.localizedDescription)
        }
    }
    
    private func setupConfettiAnimation() {
        confettiLayer1 = createConfettiLayer()
        confettiLayer2 = createConfettiLayer()
        confettiLayer3 = createConfettiLayer()
        
        confettiLayer1.emitterPosition = CGPoint(x: view.bounds.width / 4, y: -50)
        confettiLayer2.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -50)
        confettiLayer3.emitterPosition = CGPoint(x: view.bounds.width * 3 / 4, y: -50)
        
        view.layer.addSublayer(confettiLayer1)
        view.layer.addSublayer(confettiLayer2)
        view.layer.addSublayer(confettiLayer3)
    }
    
    private func createConfettiLayer() -> CAEmitterLayer {
        let confettiLayer = CAEmitterLayer()
        confettiLayer.emitterSize = CGSize(width: view.bounds.width / 4, height: view.bounds.height)
        confettiLayer.emitterShape = .line
        confettiLayer.renderMode = .additive
        
        let confettiCell = makeConfettiCell()
        confettiLayer.emitterCells = [confettiCell]
        
        // Set initial birth rate to zero
        confettiLayer.birthRate = 0
        
        return confettiLayer
    }
    
    private func makeConfettiCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 4
        cell.lifetime = 2.0
        cell.velocity = 400
        cell.velocityRange = 200
        cell.emissionLongitude = .pi
        cell.scale = 0.2
        cell.scaleRange = 0.1
        cell.spin = .pi * 2 * CGFloat.random(in:0.5...1.0)
        cell.emissionRange = .pi / 4
        
        // Array of three different colors with random RGB values
        let colors: [UIColor] = [
            randomColor(),
            randomColor(),
            randomColor()
        ]
        
        // Randomly select a color
        let randomColor = colors.randomElement()?.cgColor ?? UIColor.white.cgColor
        
        cell.color = randomColor
        
        // Create a rectangular confetti particle
        let particleSize = CGSize(width: 40, height: 20)
        let particleLayer = CALayer()
        particleLayer.bounds = CGRect(origin: .zero, size: particleSize)
        particleLayer.backgroundColor = randomColor
        
        cell.contents = image(from: particleLayer)
        
        return cell
    }
    
    private func randomColor() -> UIColor {
        let brightnessConstant: CGFloat = 3
        
        // Generate random values
        let randomRed = CGFloat.random(in: 0.88...1.0)
        let randomGreen = CGFloat.random(in: 0.88...1.0)
        let randomBlue = CGFloat.random(in: 0.88...1.0)
        
        // Normalize the sum to ensure a certain brightness
        let sum = randomRed + randomGreen + randomBlue
        let scaleFactor = brightnessConstant / sum
        
        let normalizedRed = randomRed * scaleFactor
        let normalizedGreen = randomGreen * scaleFactor
        let normalizedBlue = randomBlue * scaleFactor
        
        // Use normalizedRed, normalizedGreen, and normalizedBlue in your color creation
        _ = UIColor(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: 1.0)
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    private func image(from layer: CALayer) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: layer.bounds.size)
        let image = renderer.image { context in
            layer.render(in: context.cgContext)
        }
        return image.cgImage
    }
    
    private func setupTableView() {
        displayView.dataSource = self
        displayView.delegate = self
        displayView.register(UITableViewCell.self, forCellReuseIdentifier: entryCellIdentifier)
        displayView.separatorStyle = .none
    }
    
    
    func fetchRandomEntry() {
        do {
            let allEntries = try CDcontext.fetch(JournalEntry.fetchRequest())
            randomEntries = allEntries.shuffled()
            currentRandomEntryIndex = 0
            
            if let entry = randomEntries.first {
                displayRandomEntry(entry)
            } else {
                displayDefaultMessage()
            }
        } catch {
            print("Unable to fetch random entries:", error.localizedDescription)
        }
    }
    
    func displayDefaultMessage() {
        let defaultMessage = "Try making a New Entry (or 3)!"
        
        // Check if there are any items in the items array
        if items.isEmpty {
            let defaultLabel = UILabel()
            defaultLabel.text = defaultMessage
            defaultLabel.textAlignment = .center
            defaultLabel.textColor = textColor
            defaultLabel.font = UIFont.systemFont(ofSize: 20)
            
            displayView.backgroundView = defaultLabel
            displayView.separatorStyle = .none
        } else {
            // If there are items, set the background view to nil
            displayView.backgroundView = nil
            displayView.separatorStyle = .none
        }
    }
    
    func displayRandomEntry(_ entry: JournalEntry) {
        items = [entry]
        
        // Remove any existing background image view
        removeBackgroundImageView()
        
        if let photoLocalIdentifier = entry.photoLocalIdentifier {
            setBackgroundPhoto(with: photoLocalIdentifier)
        } else {
            defaultBackgroundPhoto()
        }

        displayView.reloadData()

        currentRandomEntryIndex += 1

        // Fade in animation for the table view text
        displayView.alpha = 0
        UIView.animate(withDuration: 1.25) {
            self.displayView.alpha = 1
        }

        let fadeInAnimation = CATransition()
        fadeInAnimation.duration = 0.5
        fadeInAnimation.type = .fade
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    //    displayView.layer.add(fadeInAnimation, forKey: "fadeAnimation")

        displayRandomEntryWorkItem = DispatchWorkItem { [weak self] in
            if let currentIndex = self?.currentRandomEntryIndex, currentIndex < self?.randomEntries.count ?? 0 {
                let nextEntry = self?.randomEntries[currentIndex]
                if let CDcontext = self?.CDcontext {
                    self?.displayRandomEntry(nextEntry ?? JournalEntry(context: CDcontext))
                } else {
                    // Handle the case when context is nil
                }
            } else {
                self?.randomEntries.shuffle()
                self?.currentRandomEntryIndex = 0

                if let entry = self?.randomEntries.first {
                    self?.displayRandomEntry(entry)
                } else {
                    self?.displayDefaultMessage()
                }
            }
        }

        if let displayRandomEntryWorkItem = displayRandomEntryWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: displayRandomEntryWorkItem)
        }
    }
    
    private func removeBackgroundImageView() {
        // Find and remove any existing background image view
        if let existingBackgroundImageView = self.view.subviews.first(where: { $0 is UIImageView }) {
            existingBackgroundImageView.removeFromSuperview()
        }
    }

    private func setBackgroundPhoto(with localIdentifier: String) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        if let asset = fetchResult.firstObject {
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false

            PHImageManager.default().requestImage(for: asset, targetSize: view.bounds.size, contentMode: .aspectFill, options: requestOptions) { [weak self] (image, _) in
                guard let backgroundImage = image else {
                    print("Failed to fetch image.")
                    return
                }

                DispatchQueue.main.async {
                    // Remove any existing background image view
                    self?.removeBackgroundImageView()

                    // Create a new image view for the new background photo
                    let backgroundImageView = UIImageView(image: backgroundImage)
                    backgroundImageView.contentMode = .scaleAspectFill
                    backgroundImageView.frame = self?.view.bounds ?? CGRect.zero

                    // Insert the background image view behind all existing subviews
                    self?.view.insertSubview(backgroundImageView, at: 0)
                }
            }
        }
    }

    
    
    private func defaultBackgroundPhoto() {
        DispatchQueue.main.async {
            // Load the image asset named "MainBackground"
            if let mainBackgroundImage = UIImage(named: "MainBackground") {
                // Set the background of the view to the image
                let backgroundImageView = UIImageView(image: mainBackgroundImage)
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.frame = self.view.bounds
                backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                // Insert the background image view behind all existing subviews
                self.view.insertSubview(backgroundImageView, at: 0)
            } else {
                // If the image asset cannot be loaded, fallback to a solid color
                self.view.backgroundColor = UIColor(named: "Pink")
            }
        }
    }
    
    //Create entry
    @IBAction func addEntry(_ sender: Any) {
        let alert = UIAlertController(title: "New Entry", message: "Which memory made you happy/content today?", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Entry text"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Date (optional)"
            // Set today's date as the default value
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            textField.text = dateFormatter.string(from: Date())
            // Set the input view to a UIDatePicker
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .date
            textField.inputView = datePicker
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let noPhotoAction = UIAlertAction(title: "No Photo", style: .default) { [weak self] _ in
            // Retrieve text and date from the alert text fields
            let entryText = alert.textFields?.first?.text
            let dateString = alert.textFields?.last?.text
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateString.flatMap { dateFormatter.date(from: $0) }
            
            // Call the method to save the entry immediately with no photo
            self?.saveEntry(with: entryText, date: date, photoLocalIdentifier: nil)
        }
        alert.addAction(noPhotoAction)
        
        let pickPhotoAction = UIAlertAction(title: "Pick Photo", style: .default) { [weak self] _ in
            // Call the method to present the image picker
            self?.presentImagePickerIfNeeded()
            
            // Update the imagePickerCompletion closure to save the entry with the selected photo's local identifier
            self?.imagePickerCompletion = { [weak self] localIdentifier in
                // Retrieve text and date from the alert text fields
                let entryText = alert.textFields?.first?.text
                let dateString = alert.textFields?.last?.text
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateString.flatMap { dateFormatter.date(from: $0) }
                
                // Call the method to save the entry immediately with the selected photo's local identifier
                self?.saveEntry(with: entryText, date: date, photoLocalIdentifier: localIdentifier)
            }
        }
        alert.addAction(pickPhotoAction)
        // Present the alert controller
        present(alert, animated: true, completion: nil)
    }

    // Function to save a new entry
    func saveEntry(with text: String?, date: Date?, photoLocalIdentifier: String?) {
        guard let text = text, !text.isEmpty else {
            print("Entry text is empty.")
            return
        }
        
        // Stop any asynchronous processes that reload the table view
        displayRandomEntryWorkItem?.cancel()
        
        let context = CDcontext

        let newEntry = JournalEntry(context: context)
        newEntry.body = text
        newEntry.timestamp = date ?? Date() // Use provided date or today's date if nil
        newEntry.photoLocalIdentifier = photoLocalIdentifier // Save the photo local identifier

        // Save the new entry to the context
        do {
            try context.save()
            print("Entry saved successfully")

            // Reload the table view data
            fetchRandomEntry()
            
            // Check if the default message is currently being displayed
            if let backgroundView = displayView.backgroundView as? UILabel,
               backgroundView.text == "Time to make some entries! The confetti will be different each time. Enjoy!" {
                // Remove the default message
                displayView.backgroundView = nil
            }
        } catch {
            print("Unable to save new entry:", error.localizedDescription)
        }
        animateConfetti()
        displayDefaultMessage()
    }

    // Function to present image picker if needed
    func presentImagePickerIfNeeded() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method to handle image selection
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Retrieve the PHAsset representing the selected image
        if let phAsset = info[.phAsset] as? PHAsset {
            // Retrieve the local identifier of the selected asset
            let localIdentifier = phAsset.localIdentifier
            // Call the imagePickerCompletion closure with the selected photo's local identifier
            imagePickerCompletion?(localIdentifier)
        } else {
            // If unable to retrieve the PHAsset, call the imagePickerCompletion closure with nil
            imagePickerCompletion?(nil)
        }
        // Dismiss the image picker controller
        picker.dismiss(animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method to handle cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    
    private func animateConfetti() {
        // Create a new emitter cell with random colors for each layer
        let newConfettiCell1 = makeConfettiCell()
        let newConfettiCell2 = makeConfettiCell()
        let newConfettiCell3 = makeConfettiCell()

        confettiLayer1.emitterCells = [newConfettiCell1]
        confettiLayer2.emitterCells = [newConfettiCell2]
        confettiLayer3.emitterCells = [newConfettiCell3]

        // Set birth rate to trigger the confetti animation for each layer
        confettiLayer1.birthRate = 12
        confettiLayer2.birthRate = 12
        confettiLayer3.birthRate = 12

        // Use a DispatchWorkItem to delay setting birthRate back to zero
        let resetBirthRateWorkItem = DispatchWorkItem { [weak self] in
            self?.confettiLayer1.birthRate = 0
            self?.confettiLayer2.birthRate = 0
            self?.confettiLayer3.birthRate = 0

            // Remove all previous animations to ensure a clean state
            self?.confettiLayer1.removeAllAnimations()
            self?.confettiLayer2.removeAllAnimations()
            self?.confettiLayer3.removeAllAnimations()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: resetBirthRateWorkItem)

        // Perform the animation using UIView.animate for each layer
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseOut], animations: {
            // Define the animation changes
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return items.count
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: entryCellIdentifier, for: indexPath)
//          let defaultValue = ""
          cell.backgroundColor = .clear
          cell.textLabel?.backgroundColor = .clear
          
          let journalEntry = items[indexPath.row]
          if let timestamp = journalEntry.timestamp {
              let dateFormatter = DateFormatter()
              dateFormatter.dateFormat = "yyyy-MM-dd"
              let dateString = dateFormatter.string(from: timestamp)
              
              cell.textLabel?.numberOfLines = 0
              cell.textLabel?.lineBreakMode = .byWordWrapping
              
              if let body = journalEntry.body {
                  cell.textLabel?.text = "\(dateString)\n\(body)"
              } else {
                  cell.textLabel?.text = dateString // Just show the date if body is nil
              }
              
//              if let photoLocalIdentifier = journalEntry.photoLocalIdentifier {
//                  // Set the background image if photoLocalIdentifier is not nil
//                  setBackgroundPhoto(with: photoLocalIdentifier)
//              } else {
//                  // Set the default background image if photoLocalIdentifier is nil
//                  defaultBackgroundPhoto()
//              }
              
              cell.textLabel?.textAlignment = .center
              cell.textLabel?.font = UIFont.systemFont(ofSize: 26)
              cell.textLabel?.textColor = textColor
          }
          
          return cell
      }
    
    // Function to present image picker
    func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
  }
