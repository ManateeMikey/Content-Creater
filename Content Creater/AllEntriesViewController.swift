//
//  AllEntriesViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-11-15.
//

import UIKit
import CoreData

class AllEntriesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var items:[JournalEntry]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register the cell class
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EntryCell")
        
        fetchEntries()
        
        // Set the table view background color with 30% opacity
        tableView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        
        // Set rounded corners for the table view
        tableView.layer.cornerRadius = 15
        
    }
    
    @objc func backButtonTapped() {
        // Handle the back button tap here (e.g., pop the view controller)
        navigationController?.popViewController(animated: true)
    }
        
    
    func fetchEntries() {
        // Fetch data from Core Data and sort it in descending order by timestamp
        let fetchRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            self.items = try context.fetch(fetchRequest)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            // Handle the error
            print("Unable to fetch entries")
        }
    }
    
    //Delete entries
    func tableView(_ tableView:UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //Create swipe action
        let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
            
            //Which person to remove
            let entryToRemove = self.items![indexPath.row]
            //Remove the person
            self.context.delete(entryToRemove)
            //Save data
            do {
                try self.context.save()
            }
            catch {
                print("Unable to delete Entry")
            }
            //Re-fetch the data
            self.fetchEntries()
        }
        
        //Return swipe actions
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    
    //Change Entry
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //Selected Entry
        let entry = self.items![indexPath.row]
        
        //Create alert
        let alert = UIAlertController(title: "Edit Entry", message: "Change this entry", preferredStyle: .alert)
        alert.addTextField()
        
        let textfield = alert.textFields![0]
        textfield.text = entry.body
        
        //Configure button handler
        let saveButton = UIAlertAction(title: "Save", style: .default) { (action) in
            
            //Get textfield for the alert
            let textfield = alert.textFields![0]
            
            //Edit name property of person object
            entry.body = textfield.text
            
            //Save the data
            do {
                try self.context.save()
            }
            catch {
                print("Unable to change entry")
            }
            //Re-fetch the data
            self.fetchEntries()
        }
        
        //Add button
        alert.addAction(saveButton)
        
        //Show alert
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func Instructions(_ sender: Any) {
        // Display "Tap to Edit" and "Swipe left to Delete" messages using labels
        let helpLabel = UILabel()
        helpLabel.text = "Tap to Edit, Swipe to Delete"
        helpLabel.font = UIFont.systemFont(ofSize: 20)
        helpLabel.textAlignment = .center
        helpLabel.textColor = UIColor.white
        
        let returnLabel = UILabel()
        returnLabel.text = "Tap Arrow to Exit"
        returnLabel.font = UIFont.systemFont(ofSize: 20)
        returnLabel.textAlignment = .center
        returnLabel.textColor = UIColor.white

        let stackView = UIStackView(arrangedSubviews: [helpLabel, returnLabel])
        stackView.axis = .vertical
        stackView.spacing = 10

        let alertView = UIView()
        alertView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: alertView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: alertView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: alertView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: alertView.bottomAnchor)
        ])

        alertView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        alertView.layer.cornerRadius = 10

        view.addSubview(alertView)

        alertView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            alertView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: -80),
            alertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            alertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Optional: Add a timer to dismiss the view after a certain duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Animate the fade-out
            UIView.animate(withDuration: 1.0, animations: {
                alertView.alpha = 0
            }) { (_) in
                alertView.removeFromSuperview()
            }
        }
    }
    
    @IBAction func BackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension AllEntriesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //Return the number of entries
        return self.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for:indexPath)
        
        // Set the background color of the cell and the label to clear
        cell.backgroundColor = .clear
        cell.textLabel?.backgroundColor = .clear

        
        //TODO: Get entries from array and set the label
        let journalEntry  = self.items![indexPath.row]
        cell.textLabel?.text = journalEntry.body
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        cell.textLabel?.text = journalEntry.body
        cell.textLabel?.textColor = UIColor(hex: 0xffffff)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20) // Adjust the font size as needed
        //cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        //cell.textLabel?.text = dateFormatter.string(from: journalEntry.timestamp!)
        
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.row == 0 {
            cell.alpha = 0
            UIView.animate(withDuration: 1.0) {
                cell.alpha = 1
            }
        }
        return cell
    }
        
}


extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}


    
