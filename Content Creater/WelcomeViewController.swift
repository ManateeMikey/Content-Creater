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
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var items: [JournalEntry]?
    
    private let entryCellIdentifier = "EntryCell"
    private let textColor = UIColor(red: 51/255.0, green: 102/255.0, blue: 153/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        //        setupBookImageView()
        
        fetchRandomEntry()
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
                print("There are no entries - try adding some :)")
            }
        } catch {
            print("Unable to fetch random entries")
        }
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
                    self?.items = []
                    self?.displayView.reloadData()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: displayRandomEntryWorkItem!)
    }
    
    //Create entry
    @IBAction func addEntry(_ sender: Any) {
        
        let alert = UIAlertController(title: "New Entry", message: "What made you happy/content today? Try to be as specific as you can!", preferredStyle: .alert)
        alert.addTextField()
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let submitButton = UIAlertAction(title: "Add", style: .default) { [weak self] (action) in
            self?.saveNewEntry(with: alert.textFields?.first?.text)
        }
        
        submitButton.setValue("New Entry", forKey: "title")
        
        alert.addAction(submitButton)
        present(alert, animated: true, completion: nil)
    }
    
    private func saveNewEntry(with text: String?) {
        guard let text = text, !text.isEmpty else { return }

        // Cancel the existing asyncAfter task
        displayRandomEntryWorkItem?.cancel()

        let newEntry = JournalEntry(context: context)
        newEntry.body = text
        newEntry.timestamp = Date()

        do {
            try context.save()
            fetchRandomEntry()
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

          cell.backgroundColor = .clear
          cell.textLabel?.backgroundColor = .clear

          if let journalEntry = items?[indexPath.row] {
              cell.textLabel?.numberOfLines = 0
              cell.textLabel?.lineBreakMode = .byWordWrapping
              cell.textLabel?.text = journalEntry.body
              cell.textLabel?.textAlignment = .center

              cell.textLabel?.font = UIFont.systemFont(ofSize: 26)
              cell.textLabel?.textColor = textColor
          }

          return cell
      }
  }
