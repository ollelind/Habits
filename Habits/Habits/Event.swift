//
//  HabitsEvent.swift
//  Habits
//
//  Created by Olof Lind on 2015-11-21.
//  Copyright © 2015 Olof Lind. All rights reserved.
//

import Foundation

class Event: NSObject, NSCoding {
    
    let name: String
    let date: NSDate
    let parameters: NSDictionary?
    let viewVisit: Bool
    
    
    private init(name: String, parameters: NSDictionary?, date: NSDate, viewVisit: Bool) {
        self.name = name
        self.parameters = parameters
        self.date = date
        self.viewVisit = viewVisit
        super.init()
    }
    
     /**
     Used for tracking UIViewControllers that has been presented.
     - parameter String: Name of a visited UIViewController
     - returns: Event object
     */
    convenience init(viewControllerName: String) {
        self.init(
            name: viewControllerName,
            parameters: nil,
            date: NSDate(),
            viewVisit: true
        )
    }
    
    /**
     Used for creating an event with a name and optional parameters
     - parameter String: Name of the event
     - parameter Dictionary<String, AnyObject>?: Optional dictionary with parameters
     - returns: Event object
     */
    convenience init(eventName: String, parameters: NSDictionary?) {
        self.init(
            name: eventName,
            parameters: parameters,
            date: NSDate(),
            viewVisit: false
        )
    }
    
    
    // MARK: NSEncoding
    
    private static let key_name = "name"
    private static let key_parameters = "parameters"
    private static let key_date = "date"
    private static let key_view_visit_bool = "view_visit"
    
    
    required convenience init?(coder decoder: NSCoder) {
        
        // Required attributes
        guard let name = decoder.decodeObjectForKey(Event.key_name) as? String else {
            return nil
        }
        
        guard let date = decoder.decodeObjectForKey(Event.key_date) as? NSDate else {
            return nil
        }
        
        // Optional attributes
        let parameters = decoder.decodeObjectForKey(Event.key_parameters) as? NSDictionary
        let viewVisit = decoder.decodeBoolForKey(Event.key_view_visit_bool)
        
        self.init(
            name: name,
            parameters:parameters,
            date:date,
            viewVisit: viewVisit
        )
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        // Required attributes
        aCoder.encodeObject(self.name, forKey: Event.key_name)
        aCoder.encodeObject(self.parameters, forKey: Event.key_parameters)
        aCoder.encodeObject(self.date, forKey: Event.key_date)
        
        // Optional attributes
        if (self.viewVisit) {
            aCoder.encodeObject(self.viewVisit, forKey: Event.key_view_visit_bool)
        }
    }
}

