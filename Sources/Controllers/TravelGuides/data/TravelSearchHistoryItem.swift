//
//  TravelSearchHistoryItem.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelSearchHistoryItem)
@objcMembers
class TravelSearchHistoryItem : NSObject {
    
    var articleFile: String? = ""
    var articleTitle: String = ""
    var lang: String = ""
    var isPartOf: String = ""
    var lastAccessed: TimeInterval = 0
    
    static func getKey(lang: String, title: String, file: String?) -> String {
        //TODO: implement file.getName()
        //return lang + ":" + title + (file != null ? ":" + file.getName() : "");
        return lang + ":" + title + ((file != nil) ? (":" + file!) : "")
    }
    
    func getKey() -> String {
        return TravelSearchHistoryItem.getKey(lang: lang, title: articleTitle, file: articleFile)
    }
    
    func getTravelBook() -> String? {
        return articleFile != nil ? TravelArticle.getTravelBook(file: articleFile!) : nil
    }
    
}
