//
//  FourSquareDB.swift
//  FoodTracker
//
//  Created by Kalpesh Balar on 10/07/16.
//  Copyright © 2016 Kalpesh Balar. All rights reserved.
//

import Foundation

// MARK: - String Extension
extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class FourSquareDB : NSObject {
    
    var session: NSURLSession
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
 
    class func sharedInstance() -> FourSquareDB {
        struct Singleton {
            static var sharedInstance = FourSquareDB()
        }
        return Singleton.sharedInstance
    }
    
    func searchPlacesByLatLon(pin: Pin, completionHandler: CompletionHander) -> NSURLSessionDataTask {
        let methodArguments = [
            "client_id": Constants.CLIENT_ID,
            "client_secret": Constants.CLIENT_SECRET,
            "section": Constants.SECTION,
            "v": Constants.VERSION,
            "ll": "\(pin.latitude),\(pin.longitude)",
            "venuePhotos" : Constants.PHOTO
        ]
        return getPlacesFromFoursquareBySearch(methodArguments, completionHandler: completionHandler)
    }
    
    func getPlacesFromFoursquareBySearch(methodArguments: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            var errorMsg = "Unknown error occured"
            var userInfo = [String : AnyObject]()
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                completionHandler(result: nil, error: error)
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    errorMsg = "Your request returned an invalid response! Status code: \(response.statusCode)!"
                } else if let response = response {
                    errorMsg = "Your request returned an invalid response! Response: \(response)!"
                } else {
                    errorMsg = "Your request returned an invalid response!"
                }
                userInfo[NSLocalizedFailureReasonErrorKey] = errorMsg
                completionHandler(result: nil, error: NSError(domain: "world", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                errorMsg = "No data was returned by the request!"
                userInfo[NSLocalizedFailureReasonErrorKey] = errorMsg
                completionHandler(result: nil, error: NSError(domain: "world", code: 1, userInfo: userInfo))
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch {
                parsedResult = nil
                errorMsg = "Could not parse the data as JSON: '\(data)'"
                userInfo[NSLocalizedFailureReasonErrorKey] = errorMsg
                completionHandler(result: nil, error: NSError(domain: "world", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Is "response" key in our result? */
            guard let resp = parsedResult["response"] as? NSDictionary else {
                errorMsg = "Cannot find keys 'response' in \(parsedResult)"
                userInfo[NSLocalizedFailureReasonErrorKey] = errorMsg
                completionHandler(result: nil, error: NSError(domain: "world", code: 1, userInfo: userInfo))
                return
            }
            
            completionHandler(result: resp, error: nil)
        }
        task.resume()
        return task
    }
    
    
    // MARK: Escape HTML Parameters
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}