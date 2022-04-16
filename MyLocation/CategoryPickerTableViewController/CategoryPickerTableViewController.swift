//
//  CategoryPickerTableViewController.swift
//  MyLocation
//
//  Created by Миляев Максим on 14.04.2022.
//

import UIKit

class CategoryPickerTableViewController: UITableViewController {
let categories = [ "No category",
                   "Apple store",
                   "Bar",
                   "BookStore",
                   "Club",
                   "Groccery store",
                   "Historic Building",
                   "house",
                   "Ice Cream Vendor",
                   "Landmark",
                   "Pub"
]
    var selectedCategoryName = ""
    var selectedIndexPath = IndexPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<categories.count{
            if selectedCategoryName == categories[i]{
                selectedIndexPath = IndexPath(row: i, section: 0)
                break
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath)
       
        var content = cell.defaultContentConfiguration()
        content.text = categories[indexPath.row]
        cell.contentConfiguration = content

        if content.text == selectedCategoryName{
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Navigation
    //----------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CategoryPickerSegue" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPath(for: cell) {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    //----------------------------------------------------------------------------------------
    // MARK: - Table view delegate
    //----------------------------------------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != selectedIndexPath.row{
            if let selectedCell = tableView.cellForRow(at: indexPath){
            selectedCell.accessoryType = .checkmark
            }
            if let oldCell = tableView.cellForRow(at: selectedIndexPath){
                oldCell.accessoryType = .none
            }
            selectedIndexPath = indexPath
            selectedCategoryName = categories[indexPath.row]
        }
    }
}
