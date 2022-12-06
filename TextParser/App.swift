//
//  App.swift
//  TextParser
//
//  Created by pat on 12/3/22.
//

import Foundation
import NaturalLanguage

@main
struct App {
    static func main() {
        print("◊ Starting TextParser now. ◊")
        let text: String = CommandLine.arguments.dropFirst().joined(separator: " ")
        print(text)
        print()
        let sentiment: Double = sentiment(for: text)
        print("Sentiment analysis: \(sentiment)")
        
        let lemma = lemmatize(string: text)
        print()
        print("Foun the following germane words:")
        for word in lemma {
            let embeddings = embeddings(for: word)
            print("\t\(word): ", embeddings.formatted(.list(type: .and)))
        }
        
        func sentiment(for string: String) -> Double {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = string
            let (sentiment, _) = tagger.tag(at: string.startIndex, unit: .paragraph, scheme: .sentimentScore)
            return Double(sentiment?.rawValue ?? "0") ?? 0
        }
        func embeddings(for word: String) -> [String] {
            var results = [String]()
            if let embedding = NLEmbedding.wordEmbedding(for: .english) {
                let similarWords: [(String, Double)] = embedding.neighbors(for: word, maximumCount: 10)
                for word in similarWords {
                    results.append("\(word.0)  has a distance of \(round(word.1 * 100)/100)")
                }
            }
            return results
        }
        func lemmatize(string: String) -> [String] {
            let tagger = NLTagger(tagSchemes: [.lemma])
            tagger.string = string
            var results = [String]()
            
            tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .lemma) { tag, range in
                let stemForm = tag?.rawValue ?? String(string[range]).trimmingCharacters(in: .whitespaces)
                if !stemForm.isEmpty {
                    results.append(stemForm)
                }
                return true
            }
            return results
        }
    }
}
