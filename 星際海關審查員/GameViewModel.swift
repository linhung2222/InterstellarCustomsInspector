import Foundation
import Observation

/// 漸進式關卡控制器（使用 iOS 17+ Observation 框架）
@Observable
final class GameViewModel {
    /// 當前執勤天數
    var day: Int = 1
    /// 玩家目前積分
    var score: Int = 0
    /// 累積失誤次數（滿 3 次結束遊戲）
    var strikes: Int = 0
    /// 當天已審查旅客人數（每滿 6 人推進至下一天）
    var inspectedCountInDay: Int = 0
    /// 遊戲是否結束
    var isGameOver: Bool = false

    /// 單日需審查之旅客配額（6 位）
    let quotaPerDay: Int = 6
    /// 最大容許失誤次數（3 次）
    let maxStrikes: Int = 3

    /// 今日動態海關法規
    var currentRegulation: DailyRegulation
    /// 當前受檢旅客
    var currentTraveler: Traveler

    /// 上一題的審查判決結果（含觸發層級與原因）
    var lastVerdict: InspectionVerdict? = nil
    /// 上一次審查是否判斷正確（nil 代表尚無紀錄）
    var lastDecisionCorrect: Bool? = nil
    /// 終端機回饋訊息
    var feedbackMessage: String = "深度邊境海關終端機已連線。請核對旅客 10 項數據與星際法規手冊後做出裁決。"

    init() {
        let initialRegulation = Self.makeRegulation(forDay: 1)
        self.currentRegulation = initialRegulation
        self.currentTraveler = TravelerGenerator.generate(for: initialRegulation, day: 1)
    }

    /// 當前天數的關卡階段說明
    var currentDayStageDescription: String {
        switch day {
        case 1:
            return "Day 1｜基礎執勤：重點檢核【第 1 層：生理紅線】與【第 6 層：基礎證件/免簽協定】"
        case 2:
            return "Day 2｜防偽與特權：解鎖【第 2 層：證件偽造/空箱走私】與【第 3 層：外交/難民豁免】"
        case 3:
            return "Day 3｜星際檢疫令：啟用【第 4 層：封鎖星系與有機體強制疫苗檢定】"
        default:
            return "Day \(day)｜全面戒嚴：六層法則全開，啟用【第 5 層：臨時禁運物、暫停目的與種族交叉限制】"
        }
    }

    /// 根據天數產生對應複雜度的每日動態法規
    static func makeRegulation(forDay day: Int) -> DailyRegulation {
        let currentYear = 3026
        let maxAllowedTemp = 38.5
        let maxAllowedRadiation = 50.0

        // 可選封鎖星系池（避開太陽系以免完全阻斷基礎免簽題型，或保留多元星系）
        let originsPool: [StarSystem] = [
            .andromeda, .kepler, .quarantineZone, .zetaHive, .voidExile, .orionIndustrial
        ]
        // 可選臨時禁運物品池（排除 .none 與一級絕對違禁品）
        let itemsPool: [ContrabandItem] = [
            .liquidMetal, .darkMatter, .neuralEraser, .queenPheromone, .radioactiveIsotope
        ]
        // 可選暫停入境目的池（排除難民庇護與外交，保留觀光、貿易、科研）
        let purposesPool: [TravelPurpose] = [.tourism, .trade, .research]

        switch day {
        case 1:
            // Day 1：僅啟用基礎文件（第 6 層）與絕對紅線（第 1 層）
            return DailyRegulation(
                currentYear: currentYear,
                bannedOrigins: [],
                bannedItems: [],
                restrictedPurpose: nil,
                requireVaccine: false,
                maxAllowedTemp: maxAllowedTemp,
                maxAllowedRadiation: maxAllowedRadiation
            )

        case 2:
            // Day 2：解鎖「偽造抓包（第 2 層）」與「特權/難民豁免（第 3 層）」
            return DailyRegulation(
                currentYear: currentYear,
                bannedOrigins: [],
                bannedItems: [],
                restrictedPurpose: nil,
                requireVaccine: false,
                maxAllowedTemp: maxAllowedTemp,
                maxAllowedRadiation: maxAllowedRadiation
            )

        case 3:
            // Day 3：啟用 bannedOrigins 與 requireVaccine（第 4 層）
            let shuffledOrigins = originsPool.shuffled()
            let selectedOrigins = Set(shuffledOrigins.prefix(2))
            return DailyRegulation(
                currentYear: currentYear,
                bannedOrigins: selectedOrigins,
                bannedItems: [],
                restrictedPurpose: nil,
                requireVaccine: true,
                maxAllowedTemp: maxAllowedTemp,
                maxAllowedRadiation: maxAllowedRadiation
            )

        default:
            // Day 4+：全面開啟所有 bannedItems、restrictedPurpose 與種族交叉限制（第 5 層）
            let shuffledOrigins = originsPool.shuffled()
            let selectedOrigins = Set(shuffledOrigins.prefix(2))

            var selectedItems = Set(itemsPool.shuffled().prefix(2))
            // 確保液態金屬高機率入選以觸發半機械人維修豁免陷阱
            if Bool.random() {
                selectedItems.insert(.liquidMetal)
            }

            let restrictedPurpose = purposesPool.randomElement()

            return DailyRegulation(
                currentYear: currentYear,
                bannedOrigins: selectedOrigins,
                bannedItems: selectedItems,
                restrictedPurpose: restrictedPurpose,
                requireVaccine: true,
                maxAllowedTemp: maxAllowedTemp,
                maxAllowedRadiation: maxAllowedRadiation
            )
        }
    }

    /// 處理玩家的「拒簽 / 核准」裁決
    func processDecision(playerApproved: Bool) {
        guard !isGameOver else { return }

        let verdict = CustomsRuleEngine.evaluate(
            traveler: currentTraveler,
            regulation: currentRegulation
        )
        lastVerdict = verdict

        let isCorrect = (playerApproved == verdict.shouldApprove)
        lastDecisionCorrect = isCorrect

        let playerActionText = playerApproved ? "【核准放行】" : "【拒簽攔截】"
        let expectedActionText = verdict.shouldApprove ? "應核准" : "應拒簽"

        if isCorrect {
            score += 100
            feedbackMessage = "✅ 裁決正確（\(playerActionText)）+100 分\n觸發層級：\(verdict.violatedLayer)\n原因：\(verdict.reason)"
        } else {
            strikes += 1
            feedbackMessage = "❌ 審查失誤（您選擇\(playerActionText)，正確為「\(expectedActionText)」）｜警告 \(strikes)/\(maxStrikes)\n觸發層級：\(verdict.violatedLayer)\n原因：\(verdict.reason)"
        }

        // 累積 3 次失誤即結束遊戲
        if strikes >= maxStrikes {
            isGameOver = true
            return
        }

        // 每審查 6 位旅客進入下一天
        inspectedCountInDay += 1
        if inspectedCountInDay >= quotaPerDay {
            day += 1
            inspectedCountInDay = 0
            currentRegulation = Self.makeRegulation(forDay: day)
            feedbackMessage += "\n📢 第 \(day - 1) 日執勤結束！已進入第 \(day) 日，請立即查閱最新每日動態指令。"
        }

        // 生成下一位受檢旅客
        currentTraveler = TravelerGenerator.generate(for: currentRegulation, day: day)
    }

    /// 重新開始新局
    func restartGame() {
        day = 1
        score = 0
        strikes = 0
        inspectedCountInDay = 0
        isGameOver = false
        lastVerdict = nil
        lastDecisionCorrect = nil
        let initialRegulation = Self.makeRegulation(forDay: 1)
        currentRegulation = initialRegulation
        currentTraveler = TravelerGenerator.generate(for: initialRegulation, day: 1)
        feedbackMessage = "終端機已重置。開始 Day 1 星際海關審查作業。"
    }
}
