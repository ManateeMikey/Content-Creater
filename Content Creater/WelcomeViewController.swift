//
//  ViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-07-27.
//
import UIKit
import CoreData
//import RevenueCat


class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var displayView: UITableView!
    var randomEntries: [JournalEntry] = []
    var currentRandomEntryIndex = 0
    var displayRandomEntryWorkItem: DispatchWorkItem?
    var confettiLayer1: CAEmitterLayer!
    var confettiLayer2: CAEmitterLayer!
    var confettiLayer3: CAEmitterLayer!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var items: [JournalEntry]?
    
    private let entryCellIdentifier = "EntryCell"
    private let textColor = UIColor(red: 51/255.0, green: 102/255.0, blue: 153/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupTableView()
        //        setupBookImageView()
        
        fetchRandomEntry()
        
        setupConfettiAnimation()
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
        cell.spin = .pi * 2
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
        let randomRed = CGFloat.random(in: 0.85...1.0)
        let randomGreen = CGFloat.random(in: 0.85...1.0)
        let randomBlue = CGFloat.random(in: 0.85...1.0)

        // Normalize the sum to ensure a certain brightness
        let sum = randomRed + randomGreen + randomBlue
        let scaleFactor = brightnessConstant / sum

        let normalizedRed = randomRed * scaleFactor
        let normalizedGreen = randomGreen * scaleFactor
        let normalizedBlue = randomBlue * scaleFactor

        // Use normalizedRed, normalizedGreen, and normalizedBlue in your color creation
        let randomColor = UIColor(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: 1.0)

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
            let allEntries = try context.fetch(JournalEntry.fetchRequest())
            randomEntries = allEntries.shuffled()
            currentRandomEntryIndex = 0
            
            if let entry = randomEntries.first {
                displayRandomEntry(entry)
            } else {
                displayDefaultMessage()
            }
        } catch {
            print("Unable to fetch random entries")
        }
    }
    
    func displayDefaultMessage() {
        let defaultMessage = "Try making a New Entry or 3!"
        items = []
        displayView.reloadData()
        
        let defaultLabel = UILabel()
        defaultLabel.text = defaultMessage
        defaultLabel.textAlignment = .center
        defaultLabel.textColor = textColor
        defaultLabel.font = UIFont.systemFont(ofSize: 20)
        
        displayView.backgroundView = defaultLabel
        displayView.separatorStyle = .none
    }
    
    func displayRandomEntry(_ entry: JournalEntry) {
        items = [entry]
        displayView.reloadData()
        
        currentRandomEntryIndex += 1
        
        let fadeInAnimation = CATransition()
        fadeInAnimation.duration = 2.0
        fadeInAnimation.type = .fade
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        displayView.layer.add(fadeInAnimation, forKey: "fadeAnimation")
        
        displayRandomEntryWorkItem = DispatchWorkItem { [weak self] in
            if let currentIndex = self?.currentRandomEntryIndex, currentIndex < self?.randomEntries.count ?? 0 {
                let nextEntry = self?.randomEntries[currentIndex]
                self?.displayRandomEntry(nextEntry ?? JournalEntry())
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: displayRandomEntryWorkItem!)
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
        
        let submitButton = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            // Retrieve text from the first text field (entry text)
            let entryText = alert.textFields?.first?.text
            // Retrieve date from the second text field (date)
            let dateString = alert.textFields?.last?.text
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.date(from: dateString ?? "")
            
            // Call the method to save the new entry
            self?.saveNewEntry(with: entryText, date: date)
            // Animate confetti
            self?.animateConfetti()
        }
        submitButton.setValue("Save", forKey: "title")
        alert.addAction(submitButton)
        
        present(alert, animated: true, completion: nil)
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
        confettiLayer1.birthRate = 13
        confettiLayer2.birthRate = 13
        confettiLayer3.birthRate = 13

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
    
    private func saveNewEntry(with text: String?, date: Date?) {
        guard let text = text, !text.isEmpty else { return }
        
        // Cancel the existing asyncAfter task
        displayRandomEntryWorkItem?.cancel()
        
        let newEntry = JournalEntry(context: context)
        newEntry.body = text
        newEntry.timestamp = date ?? Date() // Use provided date or today's date if nil
        
        do {
            try context.save()
            fetchRandomEntry()
            
            // Reset backgroundView to nil to remove the default message
            displayView.backgroundView = nil
            // Set separatorStyle back to default
            displayView.separatorStyle = .none
        } catch {
            print("Unable to save new entry")
        }
    }
}

  extension WelcomeViewController: UITableViewDelegate, UITableViewDataSource {

      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return items?.count ?? 0
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: entryCellIdentifier, for: indexPath)
          let defaultValue = ""
          cell.backgroundColor = .clear
          cell.textLabel?.backgroundColor = .clear

          if let journalEntry = items?[indexPath.row],
             let timestamp = journalEntry.timestamp {

              let dateFormatter = DateFormatter()
              dateFormatter.dateFormat = "yyyy-MM-dd"
              let dateString = dateFormatter.string(from: timestamp)

              cell.textLabel?.numberOfLines = 0
              cell.textLabel?.lineBreakMode = .byWordWrapping
              cell.textLabel?.text = "\(dateString)\n\n\(journalEntry.body ?? defaultValue)"
              cell.textLabel?.textAlignment = .center

              cell.textLabel?.font = UIFont.systemFont(ofSize: 26)
              cell.textLabel?.textColor = textColor
          }

          return cell
      }
  }
