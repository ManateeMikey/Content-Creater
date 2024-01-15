//
//  AllEntriesViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-11-15.
//

import UIKit
import CoreData

class AllEntriesViewController: UIViewController {
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var items:[JournalEntry]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.lightGray
        
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
        let fetchRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            self.items = try context.fetch(fetchRequest)

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
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
        let entry = self.items![indexPath.row]

        let alert = UIAlertController(title: "Edit Entry", message: "Change this entry", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Body"
            textField.text = entry.body
        }

        // Use a UIDatePicker as the input view for the timestamp text field
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        alert.addTextField { textField in
            textField.placeholder = "Timestamp"
            textField.text = self.dateFormatter.string(from: entry.timestamp!)
            textField.inputView = datePicker

            // Add constraints to the datePicker
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            datePicker.heightAnchor.constraint(equalToConstant: 216.0).isActive = true // Adjust the height as needed
        }
        
        let saveButton = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }

            if let bodyTextField = alert.textFields?.first,
               let body = bodyTextField.text {

                // Extract the date from the date picker
                let timestamp = datePicker.date

                entry.body = body
                entry.timestamp = timestamp

                do {
                    try self.context.save()
                    self.fetchEntries()
                } catch {
                    print("Unable to save changes")
                }
            }
        }

        alert.addAction(saveButton)
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for: indexPath)

        cell.backgroundColor = .clear
        cell.textLabel?.backgroundColor = .clear

        let journalEntry = self.items![indexPath.row]

        // Use the dateFormatter to format the timestamp without hours, minutes, and seconds
        let formattedTimestamp = dateFormatter.string(from: journalEntry.timestamp!)

        cell.textLabel?.text = "\(formattedTimestamp)\n\n\(journalEntry.body ?? "")"
        cell.textLabel?.textColor = UIColor(hex: 0xffffff)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
        cell.textLabel?.numberOfLines = 0
        
        // Align the timestamp line to the center
        cell.textLabel?.textAlignment = .center
        
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


    
