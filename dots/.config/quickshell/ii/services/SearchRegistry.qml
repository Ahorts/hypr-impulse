pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell

Item {
    id: root

    property list<var> sections: []

    // used by config components like ConfigSwitch, ConfigSpinBox
    function findSection(item) {
        while (item) {
            if (item.addKeyword) return item
            item = item.parent
        }
    }

    function tokenize(text) {
        if (!text || typeof text !== "string")
            return []

        return text
            .toLowerCase()
            .replace(/[^a-z0-9\sğüşöçıİ_\-\.]/g, " ")
            .split(/[\s_\-\.]+/)
            .filter(function(t) { return t.length > 1 })
    }

    function fuzzyMatch(word, query) {
        let wi = 0
        let qi = 0
        let score = 0

        word = word.toLowerCase()
        query = query.toLowerCase()

        while (wi < word.length && qi < query.length) {
            if (word[wi] === query[qi]) {
                score += 10
                qi++
            }
            wi++
        }

        if (qi === query.length)
            return score

        return 0
    }

    function registerSection(data) {
        let combined = (data.title + " " + data.searchStrings.join(" ")).toLowerCase()
        
        data._tokens = tokenize(combined)
        data._searchText = combined
        
        sections.push(data)
        
        // console.log("[SearchRegistry] Registered section:", data.title, "with strings:", data.searchStrings)
    }

    function getBestResult(text) {
        let results = getSearchResult(text)
        if (results.length === 0)
            return null

        results.sort((a, b) => b.score - a.score)
        return results[0]
    }

    function getResultsRanked(text) {
        let results = getSearchResult(text)
        results.sort((a, b) => b.score - a.score)
        return results
    }

    function getSearchResult(query) {
        if (!query || query.trim() === "") return []

        query = query.toLowerCase().trim()
        let queryTokens = tokenize(query)
        let results = []

        for (let section of sections) {
            let totalScore = 0
            
            // direct match
            if (section.title.toLowerCase().includes(query)) {
                totalScore += 1000
            }
            
            // direct match
            if (section._searchText.includes(query)) {
                totalScore += 500
            }
            
            for (let qToken of queryTokens) {
                for (let sToken of section._tokens) {
                    if (sToken.startsWith(qToken)) {
                        totalScore += 200
                    } else if (sToken.includes(qToken)) {
                        totalScore += 100
                    } else {
                        let fuzzyScore = fuzzyMatch(sToken, qToken)
                        if (fuzzyScore > 0) {
                            totalScore += fuzzyScore
                        }
                    }
                }
            }
            
            if (totalScore > 0) {
                results.push({
                    pageIndex: section.pageIndex,
                    title: section.title,
                    keyword: section._searchText,
                    yPos: section.yPos,
                    score: totalScore
                })
            }
        }
        
        return results
    }

    function scoreResult(result, text) {
        return result.score
    }

    // Debug
    function listAllSections() {
        console.log("=== Registered Sections ===")
        for (let i = 0; i < sections.length; i++) {
            console.log(i + ":", sections[i].title, "tokens:", sections[i]._tokens)
        }
    }
}