pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

Item {
    id: root

    property list<var> sections: [
        
    ]

    function tokenize(text) {
        if (!text || typeof text !== "string")
            return []

        return text
            .toLowerCase()
            .replace(/[^a-z0-9\s_\-\.]/g, " ")
            .split(/[\s_\-\.]+/)
            .filter(function(t) { return t.length > 2 })
    }

    function registerSection(data) {
        sections.push(data)
    }

    function getBestResult(text) {
        let results = getSearchResult(text)
        if (results.length === 0)
            return null

        results.sort((a, b) => scoreResult(b, text) - scoreResult(a, text))
        return results[0]
    }

    function getResultsRanked(text) {
        let results = getSearchResult(text)
        if (results.length === 0)
            return null

        results.sort((a, b) => scoreResult(b, text) - scoreResult(a, text))
        return results
    }

    function getSearchResult(text) {
        var results = []

        if (!text)
            return results

        var queryWords = tokenize(text)

        for (var i in root.sections) {
            var section = root.sections[i]

            var matchScore = 0
            var matchedKeyword = ""

            for (var j in section.keywords) {
                var keyword = section.keywords[j]

                for (var q in queryWords) {
                    if (keyword.includes(queryWords[q])) {
                        matchScore++
                        matchedKeyword = keyword
                    }
                }
            }

            // tüm query kelimeleri eşleştiyse
            if (matchScore > 0) {
                results.push({
                    pageIndex: section.pageIndex,
                    title: section.title,
                    keyword: matchedKeyword,
                    yPos: section.yPos,
                    matchScore: matchScore
                })
            }
        }

        return results
    }


    function scoreResult(result, text) {
        let base = result.matchScore * 300

        let keyword = result.keyword
        text = text.toLowerCase()

        if (keyword === text) return base + 1000
        if (keyword.startsWith(text)) return base + 700
        if (keyword.includes(text)) return base + 400

        return base
    }




    

}