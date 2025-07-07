//
//  OvercastDetector.swift
//  LiveWallpaper
//

import AppKit
import CoreGraphics

//print("\(window[kCGWindowOwnerName as String] ) x: \(x), y: \(y), width: \(width), height: \(height)")


func isOvercast(areaThreshold: CGFloat = 0.9) -> Bool {
        // Get the main screen's dimensions
        let screen = NSScreen.main?.frame ?? NSRect.zero
        let screenWidth = screen.width
        let screenHeight = screen.height
        let screenArea = screenWidth * screenHeight
        
        // Skip if screen dimensions are invalid
        guard screenArea > 0 else {
            //print("Invalid screen dimensions")
            return false
        }
        
        // Get the current app's process ID to exclude its windows
        let myAppPID = NSRunningApplication.current.processIdentifier
        
        // Get all on-screen windows
        let options = CGWindowListOption.optionOnScreenOnly
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as NSArray?
        
        guard let windows = windowList as? [[String: Any]] else {
            //print("Failed to retrieve window list")
            return false
        }
        
        // Iterate through all windows
        for window in windows {
            // Filter for normal application windows (layer 0) and exclude my app
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let windowPID = window[kCGWindowOwnerPID as String] as? pid_t, windowPID != myAppPID,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"] else {
                continue
            }
            
            // Create window rectangle
            let windowRect = NSRect(x: x, y: y, width: width, height: height)
            
            // Calculate visible rectangle by intersecting with screen
            let visibleRect = windowRect.intersection(screen)
            
            // Skip if there's no visible portion
            guard !visibleRect.isEmpty else {
                continue
            }
            
            // Calculate visible area
            let visibleArea = visibleRect.width * visibleRect.height
            
            // Check if the visible area covers at least areaThreshold (e.g., 90%) of the screen
            if visibleArea >= screenArea * areaThreshold {
                // Log window details for debugging
                if let ownerName = window[kCGWindowOwnerName as String] as? String,
                   let windowName = window[kCGWindowName as String] as? String {
                    //print("Found window covering >= \(areaThreshold * 100)% of screen: \(ownerName) - \(windowName)")
                    //print("Visible area: \(visibleArea), Screen area: \(screenArea), Ratio: \(visibleArea / screenArea)")
                }
                return true
            }
        }
        
        //print("No window covers >= \(areaThreshold * 100)% of the screen")
        return false
    }
