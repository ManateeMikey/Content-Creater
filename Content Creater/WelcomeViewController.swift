//
//  ViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-07-27.
//
import UIKit
import CoreData
import Photos
import StoreKit

class WelcomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SKProductsRequestDelegate {
    
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
    private let textColor = UIColor.white//UIColor(red: 51/255.0, green: 102/255.0, blue: 153/255.0, alpha: 1.0)
    
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
    
    @IBAction func TipJar(_ sender: Any) {
        // Fetch product offerings from the App Store
        fetchProductInformation()
    }

    // Function to fetch product information from the App Store
    func fetchProductInformation() {
        let productIdentifiers: Set<String> = ["com.analyticai.contentcreater.tipjarconsumable"] // Add your product identifiers here

        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }

    // Delegate method to handle product information response
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Process the products received from the App Store
        let products = response.products
        
        // Assuming you want to purchase the first available package, you can modify this as needed
        if let product = products.first {
            // Initiate a purchase for the selected product
            purchaseProduct(product)
        } else {
            print("No products available for purchase.")
        }
    }

    // Function to initiate a purchase for a product
    func purchaseProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    // Delegate method to handle transaction updates
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                // The transaction is being processed by the App Store
                break
            case .purchased:
                // The transaction was successful
                // Handle unlocking content or features for the user
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // The transaction failed
                if let error = transaction.error {
                    print("Transaction failed with error: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                // The transaction was restored
                // Handle restoring content or features for the user
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred:
                // The transaction is in the queue, but its final status is pending external action
                break
            @unknown default:
                break
            }
        }
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

        // Reload the table view with a smooth animation
        UIView.transition(with: displayView, duration: 2, options: .transitionCrossDissolve, animations: {
            self.displayView.reloadData()
        }, completion: nil)

        currentRandomEntryIndex += 1

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: displayRandomEntryWorkItem)
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

                // Create a new image view for the new background photo
                let backgroundImageView = UIImageView(image: backgroundImage)
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.frame = self?.view.bounds ?? CGRect.zero
                backgroundImageView.alpha = 0 // Set initial alpha to 0

                // Insert the background image view below the table view
                self?.view.insertSubview(backgroundImageView, belowSubview: self?.displayView ?? UIView())

                // Perform the transition animation to simultaneously decrease alpha of old background and increase alpha of new background
                UIView.animate(withDuration: 4.0, animations: {
                    // Decrease alpha of old background
                    self?.view.subviews.first(where: { $0 is UIImageView && $0 != backgroundImageView })?.alpha = 0
                    // Increase alpha of new background
                    backgroundImageView.alpha = 1
                }, completion: { _ in
                    // Remove the old background image view
                    self?.view.subviews.first(where: { $0 is UIImageView && $0 != backgroundImageView })?.removeFromSuperview()
                    
                    // Perform the fade-out animation
                    UIView.animate(withDuration: 4.0, animations: {
                        backgroundImageView.alpha = 0 // Gradually decrease alpha to 0.1
                    }, completion: { _ in
                        // Remove the new background image view after fade-out animation
                        backgroundImageView.removeFromSuperview()
                    })
                })
            }
        }
    }

    private func defaultBackgroundPhoto() {
        DispatchQueue.main.async {
            // Load the image asset named "MainBackground"
            if let mainBackgroundImage = UIImage(named: "MainBackground") {
                // Create a new image view for the default background photo
                let backgroundImageView = UIImageView(image: mainBackgroundImage)
                backgroundImageView.contentMode = .scaleAspectFill
                backgroundImageView.frame = self.view.bounds
                backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                backgroundImageView.alpha = 0 // Set initial alpha to 0

                // Insert the background image view below the table view
                self.view.insertSubview(backgroundImageView, belowSubview: self.displayView)

                // Perform the transition animation to gradually increase alpha of new background and decrease alpha of old background
                UIView.animate(withDuration: 4.0, animations: {
                    // Decrease alpha of old background
                    self.view.subviews.first(where: { $0 is UIImageView && $0 != backgroundImageView })?.alpha = 0
                    // Increase alpha of new background
                    backgroundImageView.alpha = 1
                }, completion: { _ in
                    // Remove the old background image view
                    self.view.subviews.first(where: { $0 is UIImageView && $0 != backgroundImageView })?.removeFromSuperview()
                    
                    // Perform the fade-out animation
                    UIView.animate(withDuration: 4.0, animations: {
                        backgroundImageView.alpha = 0 // Gradually decrease alpha to 0.1
                    }, completion: { _ in
                        // Remove the new background image view after fade-out animation
                        backgroundImageView.removeFromSuperview()
                    })
                })
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
        
        let noPhotoAction = UIAlertAction(title: "Save Without Photo", style: .default) { [weak self] _ in
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
        
        let pickPhotoAction = UIAlertAction(title: "Save With Photo", style: .default) { [weak self] _ in
            // Check if the app has permission to access the photo library
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                // If permission is granted, present the image picker
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
            } else {
                // If permission is not granted, display an additional popup to ask for permission
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        if status == .authorized {
                            // If permission is granted after requesting, proceed with presenting the image picker
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
                        } else {
                            // If permission is still not granted, you can handle it accordingly, such as showing a message to the user
                            let permissionAlert = UIAlertController(title: "Permission Required", message: "Please grant access to your photo library in Settings -> Content Creator to pick a photo. No one else, not even the app creator, will see or access any of your information.", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            permissionAlert.addAction(okAction)
                            self?.present(permissionAlert, animated: true, completion: nil)
                        }
                    }
                }
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
                  // Set the text to empty initially to perform fade-in animation
                  cell.textLabel?.text = ""
                  
                  // Perform the fade-in animation for the journal entry's text
                  UIView.transition(with: cell.textLabel!, duration: 2.0, options: .transitionCrossDissolve, animations: {
                      cell.textLabel?.text = "\(dateString)\n\(body)"
                  }, completion: { _ in
                      // After fade-in animation completes, perform the fade-out animation
                      UIView.animate(withDuration: 3.0, delay: 4.0, animations: {
                          cell.textLabel?.alpha = 0
                      }, completion: { _ in
                          // After fade-out animation completes, reset alpha and start fade-in animation again
                          cell.textLabel?.alpha = 1
                      })
                  })
              } else {
                  cell.textLabel?.text = dateString // Just show the date if body is nil
              }
              
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
