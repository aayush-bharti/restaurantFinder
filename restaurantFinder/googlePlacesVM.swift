//
//  googlePlacesVM.swift
//  restaurantFinder
//
//  Created by Aayush Bharti on 11/21/25.
//

import Foundation
import Combine
import CoreLocation

// overall place details struct
struct PlaceDetails {
    let name: String
    let address: String
    let rating: Double?
    let hours: [String]?
    let open_now: Bool?
}

// holds the list of responses from search api
struct SearchResponse: Decodable {
    let results: [SearchItem]
    let status: String?
    let error_message: String?
}

// holds the place id from the google places search API
struct SearchItem: Decodable {
    let place_id: String
}

// puts the placesdetailsitem into another struct
private struct DetailsResponse: Decodable {
    let result: PlaceDetailsItem
}

// struct that gets the places details api response
private struct PlaceDetailsItem: Decodable {
    let name: String
    let formatted_address: String
    let rating: Double?
    let opening_hours: GoogleHours?
}

// struct to hold the details of the hours of operation info
private struct GoogleHours: Decodable {
    let weekday_text: [String]?
    let open_now: Bool?
}

// google places VM that handles api calling
class googlePlacesVM: ObservableObject {
    // publishes teh variables needed
    @Published var placeDetails: PlaceDetails?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {}
    
    // function to get teh address of the place
    func getAddress(name: String, coordinates: CLLocationCoordinate2D) {
        // reset these values
        self.isLoading = true
        self.errorMessage = nil
        
        // create the geocoder
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        // geocodes the address using the coordinates
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            // if tehre is an error stop
            if let e = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Could not find Address: \(e.localizedDescription)"
                }
                return
            }
            
            // get all the values for the address
            if let place = placemarks?.first {
                var address: [String] = []
                if let num = place.subThoroughfare {
                    address.append(num)
                }
                
                if let street = place.thoroughfare {
                    address.append(street)
                }
                
                if let city = place.locality {
                    address.append(city)
                }
                
                if let state = place.administrativeArea {
                    address.append(state)
                }
                
                // join the values to make the address string
                let addressString = address.joined(separator: " ")
                
                print("getting more details")
                // call the function that handles all of the api
                self.getPlaceData(name: name, address: addressString)
            }
            else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Location not found"
                }
                return
            }
        }
    }
    
    
    func getPlaceData(name: String, address: String) {
        // creates the query using name and address
        let query = "\(name) \(address)"
        // encodes the query so that it is formatted properly in the url
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.isLoading = false
            return
        }
        
        // api key needed
        let apiKey = "ADD KEY"
        
        // creates the search url
        let searchUrlAsString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encodedQuery)&key=\(apiKey)"
        let searchUrl = URL(string: searchUrlAsString)!
        let searchUrlSession = URLSession.shared
        
        // uses the search url to get api response
        searchUrlSession.dataTask(with: searchUrl, completionHandler: {data, response, error -> Void in
            // if error, then stop
            if let e = error {
                DispatchQueue.main.async {
                    self.errorMessage = e.localizedDescription
                }
                return
            }
            
            do {
                // get the search response from the json
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data!)
                
                // if the place id is given, then call the details api
                if let placeId = searchResponse.results.first?.place_id {
                    // call details api with the place id to get all the information needed
                    let detailsUrlAsString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=name,rating,formatted_address,opening_hours&key=\(apiKey)"
                    let detailsUrl = URL(string: detailsUrlAsString)!
                    
                    let detailsUrlSession = URLSession.shared
                    // uses the details url to get api response
                    detailsUrlSession.dataTask(with: detailsUrl, completionHandler: {detailsData, detailsResponse, detailsError -> Void in
                        if let e = detailsError {
                            DispatchQueue.main.async {
                                self.errorMessage = e.localizedDescription
                            }
                            return
                        }
                        
                        do {
                            // get the details response from the json
                            let detailsResponse = try JSONDecoder().decode(DetailsResponse.self, from: detailsData!)
                            let result = detailsResponse.result
                            
                            // set loading to false and create the place details object to store the results
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.placeDetails = PlaceDetails(name: result.name, address: result.formatted_address, rating: result.rating, hours: result.opening_hours?.weekday_text, open_now: result.opening_hours?.open_now)
                            }
                        }
                        
                        catch {
                            print("Details Error: \(detailsError)")
                            DispatchQueue.main.async {
                                self.isLoading = false
                            }
                        }
                    }).resume()
                }
                else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "No Results Found"
                    }
                }
            }
            
            catch {
                print("Search Error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }).resume()
    }
}
