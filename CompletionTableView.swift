//
//  CompletionTableView.swift
//  completion-tableview
//
//  Created by Louis BODART on 04/08/2014.
//  Copyright (c) 2014 Louis BODART. All rights reserved.
//

import Foundation
import UIKit

class CompletionTableView : UITableView
{
    private let relatedTextField : UITextField!
    private let inView : UIView!
    private let searchInArray : [String]!
    private var tableCellIdentifier : String?
    private var completionsRegex : [String] = ["^#@"]
    
    /// Set a maximum of results that should be shown. When not set (nil) no maximum will be applied and all results will be shown.
    var maxResultsToShow: Int?
    var maxSelectedElements = 1
    /// Set a maximum height of the completion tableView. When not set (nil) no maximum calculation will be applied.
    var maxHeight: Int?
    var showSelected = false
    var resultsArray : [String] = []
    var selectedElements : [String] = []
    var completionCellForRowAtIndexPath : ((tableView: CompletionTableView, indexPath: NSIndexPath) -> UITableViewCell!)? = nil
    var completionDidSelectRowAtIndexPath : ((tableView: CompletionTableView, indexPath: NSIndexPath, value: String) -> Void)? = nil
    
    init(relatedTextField: UITextField, inView: UIView, searchInArray: [String], tableCellNibName: String?, tableCellIdentifier: String?)
    {
        self.relatedTextField = relatedTextField
        self.searchInArray = searchInArray
        self.tableCellIdentifier = tableCellIdentifier
        self.inView = inView
        
        let customFrame = CGRect(x: self.relatedTextField.frame.origin.x, y: self.relatedTextField.frame.origin.y + self.relatedTextField.frame.height,
                                 width: self.relatedTextField.frame.width, height: 0)
        
        super.init(frame: customFrame, style: UITableViewStyle.Plain)
        
        self.rowHeight = 44.0
        
        if tableCellNibName != nil {
            self.registerNib(UINib(nibName: tableCellNibName!, bundle: nil), forCellReuseIdentifier: tableCellIdentifier!)
            if self.tableCellIdentifier == nil {
                fatalError("Identifier must be set when nib name is not nil")
            }
            let tmpCell: UITableViewCell? = self.dequeueReusableCellWithIdentifier(self.tableCellIdentifier!) as UITableViewCell?
            if (tmpCell) == nil {
                fatalError("No such object exists in the reusable-cell queue")
            }
            self.rowHeight = tmpCell!.frame.height
        }
        
        self.layer.cornerRadius = 5.0
        self.delegate = self
        self.dataSource = self
        self.inView.addSubview(self)
        
        self.relatedTextField!.addTarget(self, action: #selector(CompletionTableView.onRelatedTextFieldEditingChanged(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.relatedTextField!.addTarget(self, action: #selector(CompletionTableView.onRelatedTextFieldEndEditing(_:)), forControlEvents: UIControlEvents.EditingDidEnd)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onRelatedTextFieldEditingChanged(sender: UITextField)
    {
        self.tryCompletion(sender.text!, animated: true)
    }
    
    @objc private func onRelatedTextFieldEndEditing(sender: UITextField)
    {
        self.hide(animated: true)
        self.relatedTextField.text = ""
    }
    
    private func tryCompletion(withValue: String, animated: Bool)
    {
        guard !withValue.isEmpty else {
            self.hide(animated: true)
            return
        }
        
        self.resultsArray.removeAll(keepCapacity: false)
        var maxResultsReached = false
        
        for regexString in self.completionsRegex {
            let pattern = regexString.stringByReplacingOccurrencesOfString("#@", withString: withValue)
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
                
                for entry in self.searchInArray {
                    if self.maxResultsToShow != nil && (self.resultsArray.count >= self.maxResultsToShow && self.maxResultsToShow != 0) {
                        maxResultsReached = true
                        break
                    }
                    
                    let matches = regex.matchesInString(entry, options: .Anchored, range: NSMakeRange(0, entry.characters.count ))
                    
                    if matches.count > 0
                        && !self.resultsArray.contains(entry)
                        && (self.showSelected ? true : !self.selectedElements.contains(entry)) {
                        
                        self.resultsArray.append(entry)
                    }
                }
                
                if maxResultsReached {
                    break
                }
                
            }
            catch {
                break
            }
        }
        
        self.reloadData()
        self.inView.bringSubviewToFront(self)
        self.show(animated: animated)
    }
    
    
    //MARK: - Select/Deselect manually
    
    func selectElement(element: String, maxSelectedElementsReached: (() -> Void)?) -> Bool
    {
        let tmpArray = NSArray(array: self.selectedElements)
        if tmpArray.indexOfObject(element) != NSNotFound {
            return true
        }
        if self.selectedElements.count >= self.maxSelectedElements && self.maxSelectedElements != 0 {
            if maxSelectedElementsReached != nil {
                maxSelectedElementsReached!()
            }
            return false
        }
        self.selectedElements.append(element)
        return true
    }
    
    func elementIsSelected(element: String) -> Bool
    {
        return self.selectedElements.contains(element)
    }
    
    func deselectElement(element: String)
    {
        let tmpArray = NSArray(array: self.selectedElements)
        let indexToRemove = tmpArray.indexOfObject(element)
        if indexToRemove == NSNotFound {
            return
        }
        self.selectedElements.removeAtIndex(indexToRemove)
    }
    
    
    //MARK: - Show & Hide
    
    func show(animated animated: Bool)
    {
        var newRect = self.frame
        let height = self.rowHeight * CGFloat(self.resultsArray.count)
        newRect.size.height = self.maxHeight != nil ? min(CGFloat(self.maxHeight!), height) : height
        
        if !animated {
            self.frame = newRect
            return
        }
        
        UIView.animateWithDuration(0.25) { 
            self.frame = newRect
        }
    }
    
    func hide(animated animated: Bool)
    {
        let originRect = CGRect(x: self.relatedTextField.frame.origin.x, y: self.relatedTextField.frame.origin.y + self.relatedTextField.frame.height,
                                width: self.relatedTextField.frame.width, height: self.frame.height)
        let finalRect = CGRect(x: originRect.origin.x, y: originRect.origin.y, width: originRect.width, height: 0)
        
        if !animated {
            self.frame = finalRect
            return
        }
        
        UIView.animateWithDuration(0.25) {
            self.frame = finalRect
        }
    }
}


//MARK: - TableView Delegate & DataSource

extension CompletionTableView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.resultsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if self.completionCellForRowAtIndexPath == nil {
            let cell : UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Identifier")
            
            cell.textLabel!.text = self.resultsArray[indexPath.row]
            return cell
        }
        
        return self.completionCellForRowAtIndexPath!(tableView: tableView as! CompletionTableView, indexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if self.completionDidSelectRowAtIndexPath != nil {
            self.completionDidSelectRowAtIndexPath!(tableView: tableView as! CompletionTableView,
                                                    indexPath: indexPath,
                                                    value: self.resultsArray[indexPath.row] )
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
}
