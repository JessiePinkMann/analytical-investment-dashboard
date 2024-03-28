//
//  DetailsViewController.swift
//  SwiftCharts
//
//  Created by Михаил Симаков on 24.03.2024.
//

import Foundation
import Observation

enum LoadingState {
    case fetching
    case loaded
    case error(Error)
}

final class DetailsController: ObservableObject {
    var ticker: String
    
    @Published var tickerShortName: String?
    @Published var tickerFullName: String?
    
    @Published var priceChartTimeDelta: TimeDelta = .month
    @Published var priceChartData: [TimeDelta: [ChartData]] = [:]
    @Published var priceChartLoadingState: LoadingState = .fetching
    
    @Published var indicators: [Indicator] = []
    @Published var indicatorsLoadingState: LoadingState = .fetching
    
    var indicatorsForView: [Indicator] {
        indicators.filter { $0.value != nil }
            .sorted { $0.type < $1.type }
    }
    
    struct ProsConsData {
        let pros: Int
        let cons: Int
        
        var sum: Int { pros + cons }
    }
    
    var tickerProsConsData: ProsConsData {
        var prosCount = 0
        var consCount = 0
        
        for indicator in indicators {
            guard let verdict = indicator.verdict else {
                continue
            }
            
            if verdict < 0 {
                consCount += 1
            } else if verdict > 0 {
                prosCount += 1
            }
        }
        
        return ProsConsData(pros: prosCount, cons: consCount)
    }
    
    init(ticker: String) {
        self.ticker = ticker
    }
    
    func loadPriceChartData() {
        let delta = priceChartTimeDelta
        if self.priceChartData[delta] != nil {
            return
        }
        
        self.priceChartLoadingState = .fetching
        
        NetworkManager.shared.getStockPrices(ticker, in: delta, complition: { [weak self, delta] response in
            guard let self = self else {
                return
            }
            
            switch response {
            case .success(let data):
                self.priceChartData[delta] = data
                
                if self.priceChartTimeDelta == delta {
                    self.priceChartLoadingState = .loaded
                }
            case .failure(let error):
                self.priceChartLoadingState = .error(error)
            }
        })
    }
    
    func loadIndicators() {
        if !indicators.isEmpty {
            return
        }
        
        indicatorsLoadingState = .fetching
        
        NetworkManager.shared.getStockIndicators(ticker, complition: { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                self.tickerShortName = data.shortName
                self.tickerFullName = data.fullName
                self.indicators = data.indicators
                self.indicatorsLoadingState = .loaded
            case .failure(let error):
                self.indicatorsLoadingState = .error(error)
            }
        })
    }
    
    func reloadDetails() {
        priceChartData.removeAll()
        loadPriceChartData()
    }
    
    func reloadIndicators() {
        indicators.removeAll()
        loadIndicators()
    }
}
