import Foundation
import Observation

/// 漸進式關卡與遊戲狀態控制器（使用 iOS 17+ Observation 框架管理畫面雙向綁定）
@Observable
final class GameViewModel {
    /// 當前執勤天數（由 Day 1 開始遞增，解鎖更高層級的海關法規）
    var day: Int = 1
    /// 玩家目前總積分（代表排行榜榮譽分數，在商店購物不會扣除）
    var score: Int = 0
    /// 玩家可用來購買終端機升級裝備與失誤抹除的星際幣餘額（購物與罰款時會扣除）
    var credits: Int = 0
    /// 累積失誤次數（滿 3 次即遭解僱並結束遊戲）
    var strikes: Int = 0
    /// 廉潔聲望值（檢舉行賄可提升聲望，滿 30 / 60 可於每日結算領取額外津貼）
    var reputation: Int = 0
    /// 被星際廉政署稽查開除的風險百分比（範圍 0...100，達 100% 立即逮捕撤職）
    var auditRisk: Int = 0
    /// 遊戲結束原因（nil 代表遊戲仍在進行中）
    var gameOverReason: GameOverReason? = nil
    /// 當天已審查旅客人數（每滿 6 人進入每日結算與裝備商店）
    var inspectedCountInDay: Int = 0
    /// 相容存取別名：當天已審查旅客人數
    var reviewedCountInDay: Int {
        get { inspectedCountInDay }
        set { inspectedCountInDay = newValue }
    }
    /// 遊戲是否已結束（控制 Game Over 結算遮罩顯示）
    var isGameOver: Bool = false

    /// 已購買安裝的永久輔助掃描裝備集合
    var purchasedUpgrades: Set<UpgradeItem> = []
    /// 是否正在顯示每日結算與裝備商店彈出視窗
    var isShowingDailySummary: Bool = false
    /// 當日審查判斷正確的旅客人數
    var dailyCorrectCount: Int = 0
    /// 當日審查判斷失誤的次數
    var dailyMistakeCount: Int = 0
    /// 最新一天的結算報告資料（供結算畫面呈現收支與廉政署抽查結果）
    var latestReport: DailySummaryReport? = nil

    /// 單日需審查之旅客配額上限（固定為每日 6 位旅客）
    let quotaPerDay: Int = 6
    /// 最大容許失誤次數（固定為 3 次）
    let maxStrikes: Int = 3

    /// 今日生效的動態海關法規
    var currentRegulation: DailyRegulation
    /// 當前正在接受海關審查的旅客資料
    var currentTraveler: Traveler

    /// 上一題的規則引擎審查判決結果（含觸發層級與詳細理由）
    var lastVerdict: InspectionVerdict? = nil
    /// 上一次審查是否判斷正確（nil 代表尚無紀錄或前次為私下收賄操作）
    var lastDecisionCorrect: Bool? = nil
    /// 上一次操作是否為私下收賄（供終端機底部回饋區顯示暗金色警告樣式）
    var isLastActionBribe: Bool = false
    /// 終端機底部顯示的即時回饋訊息文字
    var feedbackMessage: String = "深度邊境海關終端機已連線。請核對旅客 10 項數據與星際法規手冊後做出裁決。"

    /// 初始化遊戲狀態控制器，載入第 1 天的基礎法規與第一位受檢旅客
    init() {
        let initialRegulation = Self.makeRegulation(forDay: 1)
        self.currentRegulation = initialRegulation
        self.currentTraveler = TravelerGenerator.generate(for: initialRegulation, day: 1)
    }

    /// 當前天數的關卡階段重點說明（顯示於今日邊境緊急指令速報橫幅）
    var currentDayStageDescription: String {
        switch day {
        case 1:
            return "Day 1｜基礎執勤：重點檢核【第 1 層：生理紅線】與【第 6 層：基礎證件/免簽協定】"
        case 2:
            return "Day 2｜防偽、特權與行賄試探：解鎖【第 2 層：證件偽造/走私】、【第 3 層：外交/難民豁免】與【私密行賄通訊】"
        case 3:
            return "Day 3｜星際檢疫令：啟用【第 4 層：封鎖星系與有機體強制疫苗檢定】"
        default:
            return "Day \(day)｜全面戒嚴：六層法則全開，啟用【第 5 層：臨時禁運物、暫停目的與種族交叉限制】"
        }
    }

    /// 根據執勤天數產生對應複雜度的每日動態海關法規
    /// - Parameter day: 目標執勤天數
    /// - Returns: 對應天數難度設定的 `DailyRegulation` 實體
    static func makeRegulation(forDay day: Int) -> DailyRegulation {
        let currentYear = 3026
        let maxAllowedTemp = 38.5
        let maxAllowedRadiation = 50.0

        // 可選封鎖星系池（避開太陽系以免完全阻斷基礎免簽題型，保留多元星系組合）
        let originsPool: [StarSystem] = [
            .andromeda, .kepler, .quarantineZone, .zetaHive, .voidExile, .orionIndustrial
        ]
        // 可選臨時禁運物品池（排除 .none 與第一層一級絕對違禁品）
        let itemsPool: [ContrabandItem] = [
            .liquidMetal, .darkMatter, .neuralEraser, .queenPheromone, .radioactiveIsotope
        ]
        // 可選暫停入境目的池（排除難民庇護與外交出使，保留觀光、貿易、科研）
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
            // Day 2：解鎖「偽造抓包（第 2 層）」與「特權/難民豁免（第 3 層）」及行賄事件
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
            // Day 3：啟用封鎖星系（bannedOrigins）與強制疫苗檢疫（requireVaccine，第 4 層）
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
            // Day 4+：全面開啟所有臨時禁運品（bannedItems）、暫停目的（restrictedPurpose）與種族交叉限制（第 5 層）
            let shuffledOrigins = originsPool.shuffled()
            let selectedOrigins = Set(shuffledOrigins.prefix(2))

            var selectedItems = Set(itemsPool.shuffled().prefix(2))
            // 確保液態金屬有高機率入選，以測試玩家對「半機械人攜帶液態金屬維修豁免」的掌握度
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

    /// 處理玩家點擊「拒簽（DENY）」或「核准（APPROVE）」按鈕的裁決邏輯
    /// - Parameter playerApproved: 玩家是否選擇核准放行（true 為核准，false 為拒簽）
    func processDecision(playerApproved: Bool) {
        guard !isGameOver && !isShowingDailySummary else { return }

        // 呼叫海關規則引擎計算標準答案與觸發層級
        let verdict = CustomsRuleEngine.evaluate(
            traveler: currentTraveler,
            regulation: currentRegulation
        )
        lastVerdict = verdict

        let isCorrect = (playerApproved == verdict.shouldApprove)
        lastDecisionCorrect = isCorrect
        isLastActionBribe = false

        let playerActionText = playerApproved ? "【核准放行】" : "【拒簽攔截】"
        let expectedActionText = verdict.shouldApprove ? "應核准" : "應拒簽"

        if isCorrect {
            // 裁決正確：發放 100 積分與 100 星際幣
            score += 100
            credits += 100
            dailyCorrectCount += 1
            feedbackMessage = "✅ 裁決正確（\(playerActionText)）+100 分 / +100 ฿\n觸發層級：\(verdict.violatedLayer)\n原因：\(verdict.reason)"
        } else {
            // 裁決失誤：記 1 次失誤紅燈並提示正確法規依據
            strikes += 1
            dailyMistakeCount += 1
            feedbackMessage = "❌ 審查失誤（您選擇\(playerActionText)，正確為「\(expectedActionText)」）｜警告 \(strikes)/\(maxStrikes)\n觸發層級：\(verdict.violatedLayer)\n原因：\(verdict.reason)"
        }

        // 累積滿 3 次失誤即遭到解僱並結束遊戲
        if strikes >= maxStrikes {
            gameOverReason = .tooManyStrikes
            isGameOver = true
            return
        }

        advanceProgressAfterDecision()
    }

    /// 接受違規旅客的賄賂並私自放行（獲得賄款，但大幅提升稽查風險並扣減聲望）
    func acceptBribe() {
        guard !isGameOver && !isShowingDailySummary,
              let offer = currentTraveler.bribeOffer else { return }

        let verdict = CustomsRuleEngine.evaluate(
            traveler: currentTraveler,
            regulation: currentRegulation
        )
        lastVerdict = verdict
        lastDecisionCorrect = nil
        isLastActionBribe = true

        // 收取賄款、提高稽查風險並扣除廉潔聲望
        credits += offer.amount
        auditRisk = min(100, auditRisk + offer.riskIncrease)
        reputation = max(0, reputation - 15)
        feedbackMessage = "💰 已收取 \(offer.amount) ฿ 並私自放行，稽查風險上升至 \(auditRisk)%\n掩蓋違規：\(verdict.violatedLayer)（聲望 -15）"

        // 即時紅線判定：稽查風險達 100% 時立即遭星際廉政署逮捕並撤職
        if auditRisk >= 100 {
            gameOverReason = .firedForCorruption
            isGameOver = true
            return
        }

        advanceProgressAfterDecision()
    }

    /// 嚴正檢舉並拒簽逮捕行賄旅客（沒收賄款歸公，獲得額外積分、星際幣、聲望並降低稽查風險）
    func reportBribe() {
        guard !isGameOver && !isShowingDailySummary,
              let offer = currentTraveler.bribeOffer else { return }

        let verdict = CustomsRuleEngine.evaluate(
            traveler: currentTraveler,
            regulation: currentRegulation
        )
        lastVerdict = verdict
        lastDecisionCorrect = true
        isLastActionBribe = false

        // 發放檢舉獎勵、提升廉潔聲望並降低稽查風險
        score += 150
        credits += 120
        reputation += 20
        auditRisk = max(0, auditRisk - 10)
        dailyCorrectCount += 1
        feedbackMessage = "🛡️ 已檢舉並逮捕行賄旅客（沒收賄款 \(offer.amount) ฿）！聲望 +20、稽查風險降低（+150 分 / +120 ฿）\n查獲違規：\(verdict.violatedLayer)"

        advanceProgressAfterDecision()
    }

    /// 推進當日審查配額進度；若已達單日配額上限則觸發每日結算與廉政署抽查
    private func advanceProgressAfterDecision() {
        inspectedCountInDay += 1
        if inspectedCountInDay >= quotaPerDay {
            performDailySettlement()
            return
        }

        // 尚未達單日配額上限，生成下一位受檢旅客
        currentTraveler = TravelerGenerator.generate(for: currentRegulation, day: day)
    }

    /// 執行每日值勤結算與星際廉政署隨機抽查檢定
    private func performDailySettlement() {
        let baseReward = dailyCorrectCount * 100
        let perfectShiftBonus = (dailyMistakeCount == 0) ? 150 : 0
        if perfectShiftBonus > 0 {
            credits += perfectShiftBonus
        }

        // 1. 計算廉潔聲望津貼（聲望達 60 獲 100 津貼，達 30 獲 50 津貼）
        let reputationBonus: Int
        if reputation >= 60 {
            reputationBonus = 100
        } else if reputation >= 30 {
            reputationBonus = 50
        } else {
            reputationBonus = 0
        }

        if reputationBonus > 0 {
            score += reputationBonus
            credits += reputationBonus
        }

        // 2. 執行星際廉政署抽查機率檢定（以 auditRisk 百分比作為抽中機率）
        let auditResult: AuditResult
        if auditRisk == 0 {
            auditResult = .notTriggered
        } else if Int.random(in: 1...100) <= auditRisk {
            // 中標！遭到星際廉政署查獲帳目異常
            if auditRisk >= 75 {
                // 高風險狀態下被查獲，罪證確鑿直接逮捕撤職
                auditResult = .arrested
                gameOverReason = .firedForCorruption
                isGameOver = true
            } else {
                // 中低風險狀態下被查獲，強制扣繳罰金 250 星際幣並記 1 次重大失誤紅燈
                let penalty = 250
                auditResult = .fined(penalty: penalty)
                credits = max(0, credits - penalty)
                strikes += 1
                auditRisk = max(0, auditRisk - 20)
                if strikes >= maxStrikes {
                    gameOverReason = .tooManyStrikes
                    isGameOver = true
                }
            }
        } else {
            // 雖有風險但今日未被抽中，驚險過關
            auditResult = .passed
        }

        let totalEarned = baseReward + perfectShiftBonus + reputationBonus

        // 建立當日結算報告供商店視窗顯示
        latestReport = DailySummaryReport(
            correctCount: dailyCorrectCount,
            mistakeCount: dailyMistakeCount,
            baseReward: baseReward,
            perfectShiftBonus: perfectShiftBonus,
            reputationBonus: reputationBonus,
            auditResult: auditResult,
            totalEarned: totalEarned
        )

        // 若未在抽查中觸發 Game Over，則彈出每日結算與裝備商店視窗
        if !isGameOver {
            isShowingDailySummary = true
        }
    }

    /// 購買終端機永久升級模組或單次消耗品
    /// - Parameter item: 欲購買的升級項目
    func buyUpgrade(_ item: UpgradeItem) {
        if credits < item.cost {
            return
        } else if item == .strikeRepair {
            // 消耗品：立即消除 1 顆失誤紅燈
            if strikes > 0 {
                credits -= item.cost
                strikes -= 1
            }
        } else {
            // 永久硬體模組：加入已安裝集合
            if !purchasedUpgrades.contains(item) {
                credits -= item.cost
                purchasedUpgrades.insert(item)
            }
        }
    }

    /// 判斷指定升級項目目前是否符合購買條件（檢查餘額、是否已安裝、或是否有失誤可消除）
    /// - Parameter item: 欲檢查的升級項目
    /// - Returns: 是否可點擊購買
    func canPurchase(_ item: UpgradeItem) -> Bool {
        if credits < item.cost {
            return false
        } else if item == .strikeRepair {
            return strikes > 0
        } else {
            return !purchasedUpgrades.contains(item)
        }
    }

    /// 結束每日結算與裝備採購，推進至下一天值勤並更新當日動態法規
    func startNextDay() {
        day += 1
        reviewedCountInDay = 0
        dailyCorrectCount = 0
        dailyMistakeCount = 0
        currentRegulation = Self.makeRegulation(forDay: day)
        currentTraveler = TravelerGenerator.generate(for: currentRegulation, day: day)
        isShowingDailySummary = false
        isLastActionBribe = false
        feedbackMessage = "📢 第 \(day - 1) 日值勤結算完成！已進入第 \(day) 日，請立即查閱最新每日動態指令。"
    }

    /// 重新開始新局（重置所有天數、積分、星際幣、裝備與法規狀態至 Day 1）
    func restartGame() {
        day = 1
        score = 0
        credits = 0
        strikes = 0
        reputation = 0
        auditRisk = 0
        gameOverReason = nil
        inspectedCountInDay = 0
        dailyCorrectCount = 0
        dailyMistakeCount = 0
        purchasedUpgrades = []
        latestReport = nil
        isShowingDailySummary = false
        isGameOver = false
        lastVerdict = nil
        lastDecisionCorrect = nil
        isLastActionBribe = false
        let initialRegulation = Self.makeRegulation(forDay: 1)
        currentRegulation = initialRegulation
        currentTraveler = TravelerGenerator.generate(for: initialRegulation, day: 1)
        feedbackMessage = "終端機已重置。開始 Day 1 星際海關審查作業。"
    }
}
