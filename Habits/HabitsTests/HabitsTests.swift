//
//  HabitsTests.swift
//  HabitsTests
//
//  Created by Olof Lind on 2015-11-17.
//  Copyright © 2015 Olof Lind. All rights reserved.
//

import XCTest
@testable import Habits

class HabitsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Habits.client.deleteAllContent()
        Habits.init()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTrackEvent()
    {
        let event = Habits.trackEvent("Test")
        let event2 = Habits.trackEvent("Test", parameters: ["Param1": "testar", "Param2" : 5, "Param3" : NSDate()])
        let event3 = Habits.trackEvent("Test", parameters: ["ParamError" : NSDateFormatter()])
        
        XCTAssert(event.name == "Test")
        XCTAssert(event2.name == "Test")
        XCTAssert(event.viewVisit == false)
        XCTAssert(event2.parameters?.count == 3)
        XCTAssert(event3.parameters == nil)
    }
    
    func testTrackViewVisit()
    {
        let controller = UIViewController()
        let event = Habits.trackVisitedViewController(controller)
        
        XCTAssert(event.name == "UIViewController")
        XCTAssert(event.viewVisit == true)
        
        class CustomViewController : UIViewController {
            private override func name() -> String {
                return "CustomControllerName"
            }
        }
        let customController = CustomViewController()
        let event2 = Habits.trackVisitedViewController(customController)
        
        XCTAssert(event2.name == "CustomControllerName")
        
    }
    
    func testNotificationObserver()
    {
        let controller = UIViewController()
        let notification = NSNotification(
            name: "",
            object: nil,
            userInfo: ["UINavigationControllerNextVisibleViewController" : controller]
        )
        
        let event = Habits.client.notificationObserverViewControllerWasPresented(notification)
        XCTAssert(event != nil && event!.viewVisit)
        
        // Check that events doesn't create an event
        let emptyNotification = NSNotification(
            name: "",
            object: nil,
            userInfo: nil
        )
        let event2 = Habits.client.notificationObserverViewControllerWasPresented(emptyNotification)
        XCTAssert(event2 == nil)
    }
    
    func testEventStoring()
    {
        let eventList = Habits.client.listEventsWithName("TestEventList")
        XCTAssert(eventList.count == 0)
        
        Habits.trackEvent("TestEventList")
        let eventListModified = Habits.client.listEventsWithName("TestEventList")
        XCTAssert(eventListModified.count == 1)
    }
    
    func testCount()
    {
        Habits.trackEvent("TestCountEvents")
        Habits.trackEvent("TestCountEvents")
        let count = Habits.countEventsWithName("TestCountEvents")
        XCTAssert(count == 2)
    }
    
    func testListingEvents()
    {
        let parameters = NSDictionary(dictionary: [
            "param1": "testar",
            "param2": 5,
            "param3" : NSDate()])
        
        Habits.trackEvent("Test", parameters: parameters)
        
        var predicate = NSPredicate(format: "param1 LIKE[c] 'testar'", argumentArray: nil)
        var events = Habits.client.listEventWithName("Test", predicate:predicate)
        XCTAssert(events.count > 0)
        
        predicate = NSPredicate(format: "param2 > 3", argumentArray: nil)
        events = Habits.client.listEventWithName("Test", predicate:predicate)
        XCTAssert(events.count > 0)
        
        predicate = NSPredicate(format: "param3 > %@", argumentArray: [NSDate(timeIntervalSinceNow: -100)])
        events = Habits.client.listEventWithName("Test", predicate:predicate)
        XCTAssert(events.count > 0)
        
        predicate = NSPredicate(format: "param1 LIKE[c] 'testar_fail'", argumentArray: nil)
        events = Habits.client.listEventWithName("Test", predicate:predicate)
        XCTAssert(events.count == 0)
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
