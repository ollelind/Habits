//
//  Habits.swift
//  Habits
//
//  Created by Olof Lind on 2015-11-17.
//  Copyright © 2015 Olof Lind. All rights reserved.
//

import Foundation
import UIKit

typealias EventDictionaryType = Dictionary<String, Array<Event>>
typealias EventListType = Array<Event>

public extension UIViewController {
    func name() -> String
    {
        return String(self.dynamicType)
    }
}

class Habits {
    static let client = Habits()
    
    lazy var rootPath: String! = {
        do {
            guard let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first else {
                throw HabitsErrors.DocumentDirectoryAccess
            }
            
            let path = dir.stringByAppendingPathComponent("habits/");
            return path
            
        } catch HabitsErrors.DocumentDirectoryAccess {
            print(HabitsErrors.DocumentDirectoryAccess.description())
            return nil
        } catch {
            print(HabitsErrors.Unknown.description())
            return nil
        }
    }()
    
    init() {
        self.observeViewVisitsWithSelector("notificationObserverViewControllerWasPresented:")
        let fileManager = NSFileManager.defaultManager()
        if (!fileManager.fileExistsAtPath(self.rootPath)) {
            do {
                try fileManager.createDirectoryAtPath(self.rootPath, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
            }
        }
    }
    
    /**
     Permanently removes all data stored by Habits
     */
    func deleteAllContent() -> Bool
    {
        // Create a FileManager instance
        let fileManager = NSFileManager.defaultManager()
        if (!fileManager.fileExistsAtPath(self.rootPath)) {
            return true
        }
        
        // Delete 'subfolder' folder
        do {
            try fileManager.removeItemAtPath(self.rootPath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            return false
        }
        return true
    }
    
    // MARK: View vists
    
    private let kControllerPresentedNotification = "UINavigationControllerDidShowViewControllerNotification"
    private let kUserInfoNextVisibleViewControllerKey = "UINavigationControllerNextVisibleViewController"
    
    /**
     Registers an observer for view controller presentations
     - parameter Selector: Method that will be called on presentations
     */
    func observeViewVisitsWithSelector(selector: Selector)
    {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: selector,
            name: kControllerPresentedNotification,
            object: nil
        )
    }
    
    /**
     Gets the view controller from the notification object passed in and tracks it as an event
     */
    func notificationObserverViewControllerWasPresented(notification: NSNotification) -> Event?
    {
        guard let userInfo = notification.userInfo else {
            return nil
        }
        
        guard let nextVisibleViewController = userInfo[kUserInfoNextVisibleViewControllerKey] as? UIViewController else {
            return nil
        }
        
        return Habits.trackVisitedViewController(nextVisibleViewController)
    }
    
    
    // MARK: Tracking
    
    /**
    Tracks an event with a given name
    - parameter String: Name of the event
    - returns: Event object
    */
    class func trackEvent(name: String) -> Event
    {
        return self.trackEvent(name, parameters: nil)
    }
    
    /**
     Tracks an event wwith a given name and parameters
     - parameter String: Name of the event
     - parameter Dictionary<String, AnyObject>?: Optional dictionary with parameters
     - returns: Event object
     */
    class func trackEvent(name: String, parameters: NSDictionary?) -> Event
    {
        if let params = parameters {
            if !NSPropertyListSerialization.propertyList(params, isValidForFormat: .XMLFormat_v1_0)  {
                print("*** Error: tried to store parameters dictionary that does not conform to NSPropertyList format")
                return Event(eventName: name, parameters: nil)
            }
        }
        
        let event = Event(eventName: name, parameters: parameters)
        self.client.saveEvent(event)
        return event
    }
    
    /**
     Used for tracking view controller presentations
     - parameter UIViewController: The controller that has been presented
     - returns: Event object
     */
    class func trackVisitedViewController(viewController: UIViewController) -> Event
    {
        let nextVisibleViewControllerClassName = viewController.name()
        return Event(viewControllerName: nextVisibleViewControllerClassName)
    }
    
    /**
     Tracks an event for App start
     */
    private static let kEventNameAppStart = "AppStart"
    class func trackAppStart()
    {
        let event = Event(eventName: kEventNameAppStart, parameters: nil)
        self.client.saveEvent(event)
    }
    
    // MARK: Saving & Loading
    // Event Dictionary
    
    private let kEventStorageFileName = "events"
    private func eventDictionaryPath() -> String
    {
        return self.rootPath + "/" + kEventStorageFileName
    }
    
    /**
     Loads the main dictionary that has references to all Habit event lists
     - returns: Dictionary<String, Array<Event>>
     */
    private func eventDictionary() -> EventDictionaryType!
    {
        guard let eventDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(self.eventDictionaryPath()) as? EventDictionaryType else {
            // No events has been tracked, return an initial dictionary
            return EventDictionaryType()
        }
        return eventDictionary
    }
    
    private func saveEventsDictionary(eventDictionary: EventDictionaryType)
    {
        NSKeyedArchiver.archiveRootObject(eventDictionary, toFile: self.eventDictionaryPath())
    }
    
    private func saveEventsList(eventList: EventListType, eventName: String)
    {
        var eventDictionary = self.eventDictionary()
        eventDictionary[eventName] = eventList
        self.saveEventsDictionary(eventDictionary)
    }
    
    private func saveEvent(event: Event)
    {
        var eventList = self.listEventsWithName(event.name)
        eventList.append(event)
        self.saveEventsList(eventList, eventName: event.name)
    }
    
    // MARK: Fetching
    func listEventsWithName(eventName: String) -> EventListType!
    {
        return self.listEventWithName(eventName, predicate: nil)
    }
    
    func listEventWithName(eventName: String, predicate: NSPredicate?) -> EventListType!
    {
        if eventName.characters.count == 0 {
            return EventListType()
        }
        
        let eventDictionary = self.eventDictionary()
        if let eventList = eventDictionary[eventName] {
            
            if let p = predicate {
                let filtered = eventList.filter({
                    p.evaluateWithObject($0.parameters)
                })
                return filtered
            }
            
            return eventList
        }
        return EventListType()
    }
    
    // MARK: Helpers
    class func countEventsWithName(eventName: String) -> Int
    {
        let eventList = self.client.listEventsWithName(eventName)
        return eventList.count
    }
}

/**
 Defines error types in Habits including a string description for each
*/
enum HabitsErrors: ErrorType {
    case DocumentDirectoryAccess
    case Unknown
    
    func description() -> String
    {
        switch self {
        case .DocumentDirectoryAccess: return "Could not access Document directory"
        case .Unknown: return "An unexpected error has occured"
        }
    }
}









