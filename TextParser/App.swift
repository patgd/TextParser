//
//  App.swift
//  TextParser
//
//  Created by pat on 12/3/22.
//

import ArgumentParser
import Foundation
import NaturalLanguage

@main
struct App: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "analyze", abstract: "Analyzes input text using a range of natural language approaches.")
    }
    
    @Argument(help: "The text you want to analyze")
    var input: [String]
    
    @Flag(name: .shortAndLong, help: "Show detected language.")
    var detectLanguage = false
    
    @Flag(name: .shortAndLong, help: "Prints the input's sentiment valence.")
    var sentimentAnalysis = false
    
    @Flag(name: .shortAndLong, help: "Shows the stem form of each word.")
    var toLemmatize = false
    
    @Flag(name: .shortAndLong, help: "Prints alternative words for each word in the input.")
    var alternatives = false
    
    @Flag(name: .shortAndLong, help: "Prints names of people, places, and organizations in the input.")
    var names = false
    
    @Option(help: "The maximum number of alternative to suggest")
    var maximumAlternatives = 10
    
    mutating func run() {
        if detectLanguage == false && sentimentAnalysis == false && toLemmatize == false && alternatives == false && names == false {
            detectLanguage = true
            sentimentAnalysis = true
            toLemmatize = true
            alternatives = true
            names = true
        }
        print("◊ Starting TextParser now. ◊")
        let text = input.joined(separator: " ")
        
        if detectLanguage {
            let language = NLLanguageRecognizer.dominantLanguage(for: text) ?? .undetermined
            print()
            print("Detected language: \(language.rawValue)")
            print(text)
        }
        
        if sentimentAnalysis {
            let sentiment: Double = sentiment(for: text)
            print()
            print("Sentiment analysis: \(sentiment)")
        }
        
        if names {
            let entities = entities(for: text)
            print()
            print("Found the following entities:")
            for entity in entities { print("\t", entity) }
        }

        lazy var lemma = lemmatize(string: text)
        if toLemmatize {
            print()
            print("Found the following lemma:")
            print("\t", lemma.formatted(.list(type: .and)))
        }

        if alternatives {
            print()
            print("Found the following alternatives:")

            for word in lemma {
                let embeddings = embeddings(for: word)
                print("\t\(word): ", embeddings.formatted(.list(type: .and)))
            }
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
                let similarWords: [(String, Double)] = embedding.neighbors(for: word, maximumCount: maximumAlternatives)
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
        func entities(for string: String) -> [String] {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = string
            var results = [String]()
            
            tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .nameType, options: .joinNames) { tag, range in
                guard let tag = tag else { return true }
                let match = String(string[range])
                switch tag {
                case .organizationName:
                    results.append("Organization: \(match)")
                case .personalName:
                    results.append("Person: \(match)")
                case .placeName:
                    results.append("Place: \(match)")
                default:
                    break
                }
                return true
            }
            return results
        }
    }
}
