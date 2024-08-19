//
//  LeaderboardViewModel.swift
//  SnakeGame
//
//  Created by Ramon Jr Bahio on 7/23/24.
//

import Foundation

class LeaderboardViewModel {
    var currentPlayerName = String()
    var currentPlayerScore: Int = 0
    var currentPlayerTime = String()
    var topPlayersScores = [Int]()
    var topPlayersName = [String]()
    var topPlayersTime = [String]()
    var topPlayersStage = [Stage]()

    func load() {
        getTopScores()
    }

    private func getTopScores() {
        if UserDefaults.standard.value(forKey: TopPlayers.name.rawValue) == nil {
            //Default Values If Not Yet Set
            UserDefaults.standard.setValue("OOO,OOO,OOO,OOO,OOO", forKey: TopPlayers.name.rawValue)
            UserDefaults.standard.setValue("0,0,0,0,0", forKey: TopPlayers.score.rawValue)
            UserDefaults.standard.setValue("00:00.000,00:00.000,00:00.000,00:00.000,00:00.000", forKey: TopPlayers.time.rawValue)
            UserDefaults.standard.setValue("\(Stage.casual.rawValue),\(Stage.easy.rawValue),\(Stage.normal.rawValue),\(Stage.hard.rawValue),\(Stage.extreme.rawValue),", forKey: TopPlayers.stage.rawValue)
        }

        guard let savedScoresString = UserDefaults.standard.string(forKey: TopPlayers.score.rawValue) else { return }

        let scoresStringArray = savedScoresString.components(separatedBy: ",")
        guard let savedNamesString = UserDefaults.standard.string(forKey: TopPlayers.name.rawValue) else { return }

        let namesStringArray = savedNamesString.components(separatedBy: ",")
        guard let savedTimeString = UserDefaults.standard.string(forKey: TopPlayers.time.rawValue) else { return }

        let timesStringArray = savedTimeString.components(separatedBy: ",")
        guard let savedStageString = UserDefaults.standard.string(forKey: TopPlayers.stage.rawValue) else { return }

        topPlayersStage = getStages(savedStageString)

        for i in (0...4) {
            guard let topCurrentPlayerScore = Int(scoresStringArray[i]) else { return }
            topPlayersScores.append(topCurrentPlayerScore)
            topPlayersName.append(namesStringArray[i])
            topPlayersTime.append(timesStringArray[i])
        }
    }

    private func getStages(_ string: String) -> [Stage] {
        let stringStagesArray = string.components(separatedBy: ",")
        return stringStagesArray.map { Stage.getStage($0) }
    }

    func savePlayerName(_ player: String) {
        currentPlayerName = player
    }

    func willCurrentPlayerBeAddedOnBoard() -> Bool {
        guard topPlayersScores[gameStage.getInt()] < currentPlayerScore else { return false }
        return true
    }

    func saveNewValues() {
        UserDefaults.standard.setValue(topPlayersName.joined(separator: ","), forKey: TopPlayers.name.rawValue)
        UserDefaults.standard.setValue(topPlayersScores.compactMap({ String($0) }).joined(separator: ","), forKey: TopPlayers.score.rawValue)
        UserDefaults.standard.setValue(topPlayersTime.joined(separator: ","), forKey: TopPlayers.time.rawValue)
    }
}
