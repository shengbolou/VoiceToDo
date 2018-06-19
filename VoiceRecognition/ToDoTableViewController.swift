//
//  ToDoTableViewController.swift
//  VoiceRecognition
//
//  Created by Shengbo Lou on 6/11/18.
//  Copyright © 2018 Shengbo Lou. All rights reserved.
//

import UIKit
import Intents
import CoreData

class ToDoTableViewController: UITableViewController {
    
    var resultsController: NSFetchedResultsController<Todo>!
    var contentString: String?
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.white
        
        return refreshControl
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        resultsController = CoreDataStack.resultsController
        do{
            try resultsController.performFetch()
        }catch{
            print("Perform fetch failed!")
        }
        
        tableView.refreshControl = refresher

        resultsController.delegate = self
        
        INPreferences.requestSiriAuthorization { (status) in
            switch status{
            case .authorized:
                print("authorized")
            default:
                print("not authorized")
            }
        }
    }

    @objc
    func handleRefresh() {
        DispatchQueue.main.async{
            do {
                try self.resultsController.performFetch()
                self.tableView.reloadData()
            } catch let error  {
                print("update tableview error: \(error)")
            }
        }
        refresher.endRefreshing()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return resultsController.sections?[section].numberOfObjects ?? 0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.attributedText = getString(indexPath: indexPath, cell: cell)
        return cell
    }

    
    func getString(indexPath: IndexPath, cell: UITableViewCell) -> NSMutableAttributedString {
        let todo = resultsController.object(at: indexPath)
        let attributedString = NSMutableAttributedString(string: todo.title!)
        if todo.done {
            attributedString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 2, range: NSMakeRange(0, attributedString.length))
            cell.textLabel?.textColor = UIColor(red:0.46, green:0.46, blue:0.46, alpha:0.7)
        }
        else{
            cell.textLabel?.textColor = .black
        }
        return attributedString
    }
    
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    //MARK: - table view delegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "delete") { (action, view, completion) in
            //delete todo
            let todo = self.resultsController.object(at: indexPath)
            self.resultsController.managedObjectContext.delete(todo)
            do{
                try self.resultsController.managedObjectContext.save()
            }catch{
                print("Save task failed")
                completion(false)
            }
            completion(true)
        }
        action.image = #imageLiteral(resourceName: "if_trash")

        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let todo = self.resultsController.object(at: indexPath)
        let action = UIContextualAction(style: .destructive, title: "done") { (action, view, completion) in
            //set done to true
            self.resultsController.object(at: indexPath).done = true
            do{
                try self.resultsController.managedObjectContext.save()
            }catch{
                print("Save task failed")
            }
            completion(false)
        }
        action.image = #imageLiteral(resourceName: "check")
        action.backgroundColor = UIColor(red:0.00, green:0.78, blue:0.33, alpha:1.0)
        //if the task is completed, do not show leading swipe
        return todo.done ? nil : UISwipeActionsConfiguration(actions: [action])
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ToDoViewController{
            vc.managedContext = resultsController.managedObjectContext
        }
        
        if let cell = sender as? UITableViewCell, let vc = segue.destination as? DetailViewController{
            vc.titleString = cell.textLabel?.text
        }
    }

}

extension ToDoTableViewController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let indexPath = newIndexPath{
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath{
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            //update cell content
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath){
                cell.textLabel?.attributedText = getString(indexPath: indexPath, cell: cell)
            }
        default:
            break
        }
    }
}
