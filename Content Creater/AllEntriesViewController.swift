//
//  AllEntriesViewController.swift
//  Content
//
//  Created by Michael Xiaohang Cai on 2023-11-15.
//

import UIKit
import CoreData
import UserNotifications

class AllEntriesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var backgroundImage: UIImageView!
    var selectedImage: UIImage? // Track the selected image
    
    var isDailyNotification: Bool = true // Add this property

    
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
        
        // Set the delegate for the search bar
        EntrySearch.delegate = self
        EntrySearch.layer.cornerRadius = 15
        EntrySearch.clipsToBounds = true
        
        let selectBackgroundButton = UIButton(type: .system)
        selectBackgroundButton.setTitle("Select Background", for: .normal)
        selectBackgroundButton.addTarget(self, action: #selector(selectBackgroundPhoto), for: .touchUpInside)
        view.addSubview(selectBackgroundButton)

        // Set constraints for the button at the middle-top
        selectBackgroundButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectBackgroundButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectBackgroundButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // Initialize the UIImageView for the background image
        backgroundImage = UIImageView(frame: view.bounds)
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.clipsToBounds = true
        view.insertSubview(backgroundImage, at: 0)
        
        // Load the selected image or the default background image
        if let customImage = getCustomBackgroundImage() {
            setBackgroundImage(customImage)
        } else if let defaultBackgroundImage = UIImage(named: "HistoryBackground") {
            setBackgroundImage(defaultBackgroundImage)
        }
        
        
    }
    
    @objc func selectBackgroundPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Save the selected photo to UserDefaults
            if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                UserDefaults.standard.set(imageData, forKey: "backgroundPhoto")
                print("Custom Image Data Saved to UserDefaults: \(imageData)")
            }

            // Update the selected image
            self.selectedImage = selectedImage

            // Set the background image
            setBackgroundImage(selectedImage)
        } else if let defaultBackgroundImage = UIImage(named: "HistoryBackground") {
            // If the user did not choose a custom photo, use the "HistoryBackground" asset as a fallback
            UserDefaults.standard.removeObject(forKey: "backgroundPhoto") // Remove any previously saved custom photo
            setBackgroundImage(defaultBackgroundImage)
        }

        picker.dismiss(animated: true, completion: nil)
    }
    
    // Helper method to get the selected image from UserDefaults
    private func getCustomBackgroundImage() -> UIImage? {
        if let imageData = UserDefaults.standard.data(forKey: "backgroundPhoto"),
           let customImage = UIImage(data: imageData) {
            return customImage
        }
        return nil
    }
    
    // Helper method to set the background image
    private func setBackgroundImage(_ image: UIImage) {
        backgroundImage.image = image
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

//        // Use a UIDatePicker as the input view for the timestamp text field
//        let datePicker = UIDatePicker()
//        datePicker.datePickerMode = .date
//        datePicker.date = entry.timestamp ?? Date()  // Set the initial date

        alert.addTextField { textField in
            textField.placeholder = "Timestamp"
            textField.text = self.dateFormatter.string(from: entry.timestamp ?? Date())
//            textField.inputView = datePicker
        }

        let saveButton = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }

            if let bodyTextField = alert.textFields?.first,
               let timestampTextField = alert.textFields?.last,
               let body = bodyTextField.text,
               let timestampText = timestampTextField.text {

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"  // Adjust the format based on your timestamp format

                if let timestamp = dateFormatter.date(from: timestampText) {
                    entry.body = body
                    entry.timestamp = timestamp

                    do {
                        try self.context.save()
                        self.fetchEntries()
                    } catch {
                        print("Unable to save changes")
                    }
                } else {
                    // Invalid timestamp format, show an error alert
                    let errorAlert = UIAlertController(title: "Invalid Date Format", message: "Please enter a valid date in the format 'yyyy-MM-dd'", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    errorAlert.addAction(okAction)
                    self.present(errorAlert, animated: true, completion: nil)
                }
            }
        }

        alert.addAction(saveButton)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func Instructions(_ sender: Any) {
        // Display "Tap to Edit" and "Swipe left to Delete" messages using labels
        let helpLabel = UILabel()
        helpLabel.text = "Tap to Edit Entries/Background, Swipe to Delete"
        helpLabel.font = UIFont.systemFont(ofSize: 20)
        helpLabel.textAlignment = .center
        helpLabel.textColor = UIColor.white
        
        let returnLabel = UILabel()
        returnLabel.text = "Tap Left Arrow to Exit"
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
    
    @IBOutlet weak var EntrySearch: UISearchBar!
    
    // Add a function to schedule notifications
    func scheduleNotification(isDaily: Bool, selectedTime: Date) {
        let notificationCenter = UNUserNotificationCenter.current()

        // Remove existing notifications
        notificationCenter.removeAllPendingNotificationRequests()

        // Create a notification content
        let content = UNMutableNotificationContent()
        content.title = "Don't forget to write your microjournal entry!"
        content.body = "Take a moment to record what made you happy or content."
        content.sound = UNNotificationSound.default

        // Set the notification trigger based on user preferences
        let trigger: UNNotificationTrigger
        if isDaily {
            // Schedule daily notifications at the selected time
            let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        } else {
            // Schedule weekly notifications at the selected time on the first day of the week (e.g., Sunday)
            let weekdayComponent = Calendar.current.component(.weekday, from: selectedTime)
            let components = DateComponents(hour: Calendar.current.component(.hour, from: selectedTime),
                                            minute: Calendar.current.component(.minute, from: selectedTime),
                                            weekday: weekdayComponent)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        // Create a notification request
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        // Add the notification request to the notification center
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }

    // Add a function to handle the user's notification preference and time
    func setNotificationPreferences(isDaily: Bool, selectedTime: Date) {
        UserDefaults.standard.set(isDaily, forKey: "isDailyNotification")
        UserDefaults.standard.set(selectedTime, forKey: "notificationTime")
        scheduleNotification(isDaily: isDaily, selectedTime: selectedTime)
    }

    // Add a function to show a time picker for notification time
    func showTimePicker() {
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        
        // Set the initial time of the picker to the existing schedule time, if available
        if let notificationTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            timePicker.date = notificationTime
        }

        let alertController = UIAlertController(title: "Select Notification Time", message: nil, preferredStyle: .actionSheet)
        alertController.view.addSubview(timePicker)

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            let selectedTime = timePicker.date
            self.setNotificationPreferences(isDaily: self.isDailyNotification, selectedTime: selectedTime)
        }
        alertController.addAction(saveAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    // Add an IBAction to handle the notification settings button
    @IBAction func notificationSettingsButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Notification Settings", message: nil, preferredStyle: .actionSheet)

        let dailyAction = UIAlertAction(title: "Daily", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.isDailyNotification = true
            self.showTimePicker()
        }
        alertController.addAction(dailyAction)

        let weeklyAction = UIAlertAction(title: "Weekly", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.isDailyNotification = false
            self.showTimePicker()
        }
        alertController.addAction(weeklyAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
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
//        let formattedTimestamp = dateFormatter.string(from: journalEntry.timestamp!)

//        cell.textLabel?.text = "\(formattedTimestamp)\n\n\(journalEntry.body ?? "")"
        cell.textLabel?.text = "\(journalEntry.body ?? "")"
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


extension AllEntriesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    // Helper method to filter entries based on search text
    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            // If search text is empty, display all entries
            fetchEntries()
        } else {
            // Filter entries based on search text
            let fetchRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
            let predicate = NSPredicate(format: "body CONTAINS[c] %@", searchText)
            fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]

            do {
                self.items = try context.fetch(fetchRequest)

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Unable to fetch filtered entries")
            }
        }
    }
}
