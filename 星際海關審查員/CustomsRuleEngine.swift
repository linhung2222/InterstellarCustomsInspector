import Foundation

/// 終端機升級裝備即時掃描警示結果資料結構
struct ScannerAlerts: Equatable {
    /// 生理體溫是否超標異常（已考量矽基高溫豁免與氣態體免檢）
    var isTempAbnormal: Bool
    /// 輻射劑量是否超標異常（已考量獵戶座重工區 +25 mSv 寬容額度）
    var isRadiationAbnormal: Bool
    /// 是否偵測到第二層證件偽造或欄位邏輯矛盾
    var isForgeryDetected: Bool
    /// 偽造或邏輯矛盾的具體提示文字（供護照頂部黃色警示橫幅顯示）
    var forgeryHint: String?
    /// 護照到期年份是否小於當前星曆年份（已過期）
    var isExpired: Bool
    /// 是否觸發任何來源星系封鎖或違禁/禁運物品警報
    var isContrabandOrBanned: Bool
    /// 旅客來源星系是否位於今日緊急封鎖名單中
    var isOriginBanned: Bool = false
    /// 申報物品是否屬於一級違禁品、違反物種/目的專屬限制或今日臨時禁運品
    var isItemBannedOrContraband: Bool = false
}

/// 星際海關六層漏斗式規則比對引擎
struct CustomsRuleEngine {
    /// 供升級掃描裝備呼叫：使用與 `evaluate` 完全一致的例外規則，回傳各項指標是否觸發異常警示
    /// - Parameters:
    ///   - traveler: 當前受檢旅客資料
    ///   - regulation: 今日動態海關法規
    /// - Returns: 各項硬體掃描模組對應的異常警示狀態
    static func scanAlerts(for traveler: Traveler, regulation: DailyRegulation) -> ScannerAlerts {
        // 1. 生理體溫與輻射掃描（內建矽基高溫豁免、氣態體純輻射判定與獵戶座 +25 mSv 寬容值）
        let isTempAbnormal: Bool
        let isRadiationAbnormal: Bool

        if traveler.species == .gasEntity {
            // 氣態能量體無體溫概念，僅檢定輻射是否超過標準上限
            isTempAbnormal = false
            isRadiationAbnormal = traveler.radiationLevel > regulation.maxAllowedRadiation
        } else {
            // 非矽基生命且體溫超過上限時標記為體溫異常
            if traveler.species != .silicon && traveler.bodyTemperature > regulation.maxAllowedTemp {
                isTempAbnormal = true
            } else {
                isTempAbnormal = false
            }

            // 獵戶座重工區居民享有額外 +25.0 mSv 輻射寬容值
            let allowedRadiation = traveler.origin == .orionIndustrial
                ? regulation.maxAllowedRadiation + 25.0
                : regulation.maxAllowedRadiation
            if traveler.radiationLevel > allowedRadiation {
                isRadiationAbnormal = true
            } else {
                isRadiationAbnormal = false
            }
        }

        // 2. 證件偽造與邏輯矛盾掃描（核對外交官身分、克隆人編號前綴與空箱行李超重）
        let isForgeryDetected: Bool
        let forgeryHint: String?

        if traveler.hasDiplomaticImmunity && traveler.species != .diplomat {
            isForgeryDetected = true
            forgeryHint = "非外交官種族持有外交豁免令"
        } else if traveler.species == .clone && !traveler.serialCode.hasPrefix("CLN-") {
            isForgeryDetected = true
            forgeryHint = "克隆人編號缺少 CLN- 法定前綴"
        } else if traveler.declaredItem == .none && traveler.baggageWeight > 25.0 {
            isForgeryDetected = true
            forgeryHint = "申報無物品但行李重達 \(String(format: "%.1f", traveler.baggageWeight)) kg (>25kg)"
        } else {
            isForgeryDetected = false
            forgeryHint = nil
        }

        // 3. 護照效期核對（到期年份早於當前星曆年份即為過期）
        let isExpired: Bool
        if traveler.passportExpiryYear < regulation.currentYear {
            isExpired = true
        } else {
            isExpired = false
        }

        // 4. 違禁品與禁區雷達（一級違禁品、今日封鎖星系、今日禁運物品，自動排除半機械人攜帶液態金屬的合法例外）
        let isOriginBanned: Bool
        if regulation.bannedOrigins.contains(traveler.origin) {
            isOriginBanned = true
        } else {
            isOriginBanned = false
        }

        let isItemBannedOrContraband: Bool
        if traveler.declaredItem == .alienSpore || traveler.declaredItem == .quantumCore {
            // 第一層一級絕對違禁品
            isItemBannedOrContraband = true
        } else if traveler.declaredItem == .queenPheromone && traveler.species != .insectoid {
            // 非蟲族工蜂攜帶蟲后費洛蒙
            isItemBannedOrContraband = true
        } else if traveler.declaredItem == .darkMatter && traveler.purpose != .research {
            // 非科學研究目的攜帶暗物質電池
            isItemBannedOrContraband = true
        } else if regulation.bannedItems.contains(traveler.declaredItem) {
            // 若為今日臨時禁運物品，須排除「半機械人攜帶液態金屬」的維修自用豁免
            if traveler.declaredItem == .liquidMetal && traveler.species == .cyborg {
                isItemBannedOrContraband = false
            } else {
                isItemBannedOrContraband = true
            }
        } else {
            isItemBannedOrContraband = false
        }

        // 綜合判定是否觸發禁區或違禁品雷達
        let isContrabandOrBanned = isOriginBanned || isItemBannedOrContraband

        return ScannerAlerts(
            isTempAbnormal: isTempAbnormal,
            isRadiationAbnormal: isRadiationAbnormal,
            isForgeryDetected: isForgeryDetected,
            forgeryHint: forgeryHint,
            isExpired: isExpired,
            isContrabandOrBanned: isContrabandOrBanned,
            isOriginBanned: isOriginBanned,
            isItemBannedOrContraband: isItemBannedOrContraband
        )
    }

    /// 依據 6 個優先層級的漏斗式結構進行嚴格審查（高層級優先於低層級，一旦觸發立即回傳判決）
    /// - Parameters:
    ///   - traveler: 當前受檢旅客資料
    ///   - regulation: 今日動態海關法規
    /// - Returns: 包含是否核准、詳細理由與觸發法規層級的審查判決結果
    static func evaluate(traveler: Traveler, regulation: DailyRegulation) -> InspectionVerdict {
        // =========================================================================
        // 【第一層：絕對安全與雙軌生理紅線】（最高優先級，連外交官與難民都不可豁免）
        // =========================================================================
        if traveler.declaredItem == .alienSpore || traveler.declaredItem == .quantumCore {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "攜帶一級星際違禁品「\(traveler.declaredItem.shortName)」，觸發絕對安全紅線（任何外交與人道特權均不可豁免）。",
                violatedLayer: "第一層：絕對安全與雙軌生理紅線"
            )
        } else if traveler.species == .gasEntity {
            // 氣態生命無體溫，改檢定高能輻射劑量
            if traveler.radiationLevel > regulation.maxAllowedRadiation {
                let radText = String(format: "%.1f mSv", traveler.radiationLevel)
                let maxText = String(format: "%.1f mSv", regulation.maxAllowedRadiation)
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "氣態能量體高能輻射超標（實測 \(radText) > 上限 \(maxText)），禁止入境。",
                    violatedLayer: "第一層：絕對安全與雙軌生理紅線"
                )
            }
        } else {
            // 非氣態生命：依序檢定生理體溫與輻射劑量（矽基生命豁免體溫上限）
            if traveler.species != .silicon && traveler.bodyTemperature > regulation.maxAllowedTemp {
                let tempText = String(format: "%.1f°C", traveler.bodyTemperature)
                let maxText = String(format: "%.1f°C", regulation.maxAllowedTemp)
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "生理體溫異常（實測 \(tempText) > 上限 \(maxText)），且非矽基生命，強制檢疫拒簽。",
                    violatedLayer: "第一層：絕對安全與雙軌生理紅線"
                )
            }

            // 計算該旅客適用的輻射上限（獵戶座重工區居民享有 +25 mSv 寬容值）
            let allowedRadiation = traveler.origin == .orionIndustrial
                ? regulation.maxAllowedRadiation + 25.0
                : regulation.maxAllowedRadiation
            if traveler.radiationLevel > allowedRadiation {
                let radText = String(format: "%.1f mSv", traveler.radiationLevel)
                let maxText = String(format: "%.1f mSv", allowedRadiation)
                let note = traveler.origin == .orionIndustrial ? "（已含獵戶座重工區 +25 mSv 寬容值）" : ""
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "輻射劑量超標（實測 \(radText) > 容許上限 \(maxText)\(note)），禁止入境。",
                    violatedLayer: "第一層：絕對安全與雙軌生理紅線"
                )
            }
        }

        // =========================================================================
        // 【第二層：證件偽造與邏輯矛盾抓包】（比對護照欄位之間是否自相矛盾）
        // =========================================================================
        if traveler.hasDiplomaticImmunity && traveler.species != .diplomat {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "偽造外交豁免令：旅客種族為「\(traveler.species.shortName)」，非星際外交官種族不可能擁有外交豁免權。",
                violatedLayer: "第二層：證件偽造與邏輯矛盾抓包"
            )
        } else if traveler.species == .clone && !traveler.serialCode.hasPrefix("CLN-") {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "非法克隆體：證件編號「\(traveler.serialCode)」缺少法定 CLN- 基因序號前綴。",
                violatedLayer: "第二層：證件偽造與邏輯矛盾抓包"
            )
        } else if traveler.declaredItem == .none && traveler.baggageWeight > 25.0 {
            let weightText = String(format: "%.1f kg", traveler.baggageWeight)
            return InspectionVerdict(
                shouldApprove: false,
                reason: "疑似走私夾帶：申報「無攜帶物品」，但隨身行李重量達 \(weightText)（超過 25.0 kg 空箱上限）。",
                violatedLayer: "第二層：證件偽造與邏輯矛盾抓包"
            )
        }

        // =========================================================================
        // 【第三層：特殊身分與人道豁免覆寫】（外交特權與難民庇護可直接覆寫第 4~6 層限制）
        // =========================================================================
        if traveler.species == .diplomat && traveler.hasDiplomaticImmunity {
            return InspectionVerdict(
                shouldApprove: true,
                reason: "外交特權豁免放行：正統星際外交官持有有效外交豁免令，依法豁免後續封鎖區、簽證與護照效期限制。",
                violatedLayer: "第三層：特殊身分與人道豁免覆寫"
            )
        } else if traveler.purpose == .asylum {
            // 難民庇護者若未攜帶任何特殊管制品可直接人道放行，否則立即違反庇護條款拒簽
            if traveler.declaredItem == .none {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "星際人道庇護放行：難民庇護身分未攜帶任何特殊物品，依法豁免封鎖區、簽證與過期護照限制。",
                    violatedLayer: "第三層：特殊身分與人道豁免覆寫"
                )
            } else {
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "違反難民庇護條款：申請難民庇護者嚴禁攜帶任何特殊管制物品（申報攜帶：\(traveler.declaredItem.shortName)）。",
                    violatedLayer: "第三層：特殊身分與人道豁免覆寫"
                )
            }
        }

        // =========================================================================
        // 【第四層：每日動態緊急指令】（封鎖星系、暫停入境目的、有機體強制疫苗檢疫）
        // =========================================================================
        if regulation.bannedOrigins.contains(traveler.origin) {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "星系封鎖令攔截：旅客來自今日緊急封鎖星系「\(traveler.origin.shortName)」，暫停入境。",
                violatedLayer: "第四層：每日動態緊急指令"
            )
        } else if let restricted = regulation.restrictedPurpose, traveler.purpose == restricted {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "入境目的管制攔截：今日緊急暫停受理「\(restricted.shortName)」目的之入境申請。",
                violatedLayer: "第四層：每日動態緊急指令"
            )
        } else if regulation.requireVaccine && traveler.species.isOrganic && !traveler.hasVaccineCert {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "星際防疫攔截：今日啟動強制檢疫，「\(traveler.species.shortName)」屬於有機生命體且未持有疫苗證明。",
                violatedLayer: "第四層：每日動態緊急指令"
            )
        }

        // =========================================================================
        // 【第五層：受控物品與種族/目的交叉檢定】（含半機械人攜帶液態金屬的巢狀例外）
        // =========================================================================
        var usedCyborgLiquidMetalExemption = false

        if traveler.declaredItem == .queenPheromone && traveler.species != .insectoid {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "種族專屬管制違規：非蟲族工蜂（當前為\(traveler.species.shortName)）嚴禁攜帶「蟲后費洛蒙」。",
                violatedLayer: "第五層：受控物品與種族/目的交叉檢定"
            )
        } else if traveler.declaredItem == .darkMatter && traveler.purpose != .research {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "目的專屬管制違規：「暗物質電池」僅限「科學研究」目的攜帶（當前目的為\(traveler.purpose.shortName)）。",
                violatedLayer: "第五層：受控物品與種族/目的交叉檢定"
            )
        } else if regulation.bannedItems.contains(traveler.declaredItem) {
            // 巢狀例外：半機械人攜帶液態金屬為維修自用豁免，不提前回傳，繼續往下執行第六層基礎證件核對
            if traveler.declaredItem == .liquidMetal && traveler.species == .cyborg {
                usedCyborgLiquidMetalExemption = true
            } else {
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "臨時禁運令攔截：攜帶今日公告禁運物品「\(traveler.declaredItem.shortName)」，禁止入境。",
                    violatedLayer: "第五層：受控物品與種族/目的交叉檢定"
                )
            }
        }

        // =========================================================================
        // 【第六層：基礎文件與貿易協定核對】（護照有效期限與星系免簽協定）
        // =========================================================================
        if traveler.passportExpiryYear < regulation.currentYear {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "基礎文件無效：護照到期年份（\(traveler.passportExpiryYear) 年）早於當前星曆（\(regulation.currentYear) 年），護照已過期。",
                violatedLayer: "第六層：基礎文件與貿易協定核對"
            )
        } else if !traveler.hasEntryPermit {
            // 未持有入境許可證時，檢查是否符合太陽系公民免簽或天狼星商務免簽協定
            if traveler.origin == .solar {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "免簽協定核准放行：太陽系公民享有免簽證入境待遇，且所有安全、防疫與文件檢定均合規。",
                    violatedLayer: "第六層：基礎文件與貿易協定核對（太陽系免簽）"
                )
            } else if traveler.origin == .siriusFederation && traveler.purpose == .trade {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "商務協定核准放行：天狼星貿易聯邦公民以「商務貿易」目的入境享有免簽待遇，且各項檢定合規。",
                    violatedLayer: "第六層：基礎文件與貿易協定核對（天狼星商務免簽）"
                )
            } else {
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "缺少入境許可證：來自「\(traveler.origin.shortName)」且目的為「\(traveler.purpose.shortName)」，不適用免簽協定。",
                    violatedLayer: "第六層：基礎文件與貿易協定核對"
                )
            }
        } else {
            // 最終通過分支：所有六層檢定皆合規，針對觸發特殊豁免的案例提供明確回饋說明
            if usedCyborgLiquidMetalExemption {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "核准放行：半機械人攜帶液態金屬符合維修自用豁免條款，且護照與入境許可證齊全有效。",
                    violatedLayer: "第六層：全數檢定合規（含第五層半機械人維修豁免）"
                )
            } else if traveler.species == .silicon && traveler.bodyTemperature > regulation.maxAllowedTemp {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "核准放行：矽基生命天生高溫豁免體溫上限，且所有文件與安全檢定皆合規。",
                    violatedLayer: "第六層：全數檢定合規（含第一層矽基高溫豁免）"
                )
            } else if traveler.origin == .orionIndustrial && traveler.radiationLevel > regulation.maxAllowedRadiation {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "核准放行：獵戶座重工區居民享有 +25 mSv 輻射寬容額度，且所有文件與安全檢定皆合規。",
                    violatedLayer: "第六層：全數檢定合規（含第一層獵戶座輻射寬容）"
                )
            } else {
                return InspectionVerdict(
                    shouldApprove: true,
                    reason: "核准放行：旅客通過全部六層海關安全、防偽、防疫、管制物與基礎證件檢定。",
                    violatedLayer: "第六層：全數檢定合規"
                )
            }
        }
    }
}
