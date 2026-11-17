import Foundation

/// 星際海關六層漏斗式規則比對引擎
struct CustomsRuleEngine {
    /// 依據 6 個優先層級的 if / else if / else 結構進行嚴格審查（高層級優先於低層級）
    static func evaluate(traveler: Traveler, regulation: DailyRegulation) -> InspectionVerdict {
        // =========================================================================
        // 【第一層：絕對安全與雙軌生理紅線】（最高優先，連外交官與難民都不可豁免）
        // =========================================================================
        if traveler.declaredItem == .alienSpore || traveler.declaredItem == .quantumCore {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "攜帶一級星際違禁品「\(traveler.declaredItem.shortName)」，觸發絕對安全紅線（任何外交與人道特權均不可豁免）。",
                violatedLayer: "第一層：絕對安全與雙軌生理紅線"
            )
        } else if traveler.species == .gasEntity {
            // 氣態生命無體溫，改檢定輻射
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
            // 非氣態生命：檢定體溫與輻射
            if traveler.species != .silicon && traveler.bodyTemperature > regulation.maxAllowedTemp {
                let tempText = String(format: "%.1f°C", traveler.bodyTemperature)
                let maxText = String(format: "%.1f°C", regulation.maxAllowedTemp)
                return InspectionVerdict(
                    shouldApprove: false,
                    reason: "生理體溫異常（實測 \(tempText) > 上限 \(maxText)），且非矽基生命，強制檢疫拒簽。",
                    violatedLayer: "第一層：絕對安全與雙軌生理紅線"
                )
            }

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
        // 【第二層：證件偽造與邏輯矛盾抓包】（比對欄位之間是否自相矛盾）
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
        // 【第三層：特殊身分與人道豁免覆寫】
        // =========================================================================
        if traveler.species == .diplomat && traveler.hasDiplomaticImmunity {
            return InspectionVerdict(
                shouldApprove: true,
                reason: "外交特權豁免放行：正統星際外交官持有有效外交豁免令，依法豁免後續封鎖區、簽證與護照效期限制。",
                violatedLayer: "第三層：特殊身分與人道豁免覆寫"
            )
        } else if traveler.purpose == .asylum {
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
        // 【第四層：每日動態緊急指令】
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
        // 【第五層：受控物品與種族/目的交叉檢定】
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
            // 巢狀例外：半機械人攜帶液態金屬為維修自用豁免，不 return，繼續往下執行第六層
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
        // 【第六層：基礎文件與貿易協定核對】
        // =========================================================================
        if traveler.passportExpiryYear < regulation.currentYear {
            return InspectionVerdict(
                shouldApprove: false,
                reason: "基礎文件無效：護照到期年份（\(traveler.passportExpiryYear) 年）早於當前星曆（\(regulation.currentYear) 年），護照已過期。",
                violatedLayer: "第六層：基礎文件與貿易協定核對"
            )
        } else if !traveler.hasEntryPermit {
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
            // 最終 else：所有多重檢定皆合規
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
