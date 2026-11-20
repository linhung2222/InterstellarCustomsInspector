import Foundation

/// 智慧陷阱旅客生成器（確保約 50% 合規、50% 違規，並依天數生成高度迷惑性的邊界案例與動態行賄事件）
struct TravelerGenerator {
    /// 預設星際旅客中英文姓名庫
    private static let names = [
        "艾克斯 (Axel)", "諾娃 (Nova)", "凱隆 (Chiron)", "賽琳娜 (Selene)",
        "奧利安 (Orion)", "維加 (Vega)", "澤塔 (Zeta)", "卡珊德拉 (Cassandra)",
        "雷克斯 (Rex)", "萊拉 (Lyra)", "索恩 (Thane)", "伊歐 (Io)",
        "克羅諾斯 (Kronos)", "阿斯特拉 (Astra)", "塔羅斯 (Talos)", "妮克絲 (Nyx)",
        "凱斯 (Kael)", "薇拉 (Vesper)", "達里烏斯 (Darius)", "米拉 (Mira)"
    ]

    /// 一般非克隆人物種使用的標準證件編號前綴庫
    private static let normalSerialPrefixes = ["ID", "ST", "VX", "KR", "NV", "ARC"]

    /// 隨機產生一般證件編號（例如 "VX-4829"）
    private static func randomNormalSerial() -> String {
        let prefix = normalSerialPrefixes.randomElement() ?? "ID"
        return "\(prefix)-\(Int.random(in: 1000...9999))"
    }

    /// 隨機產生合法的克隆人專屬證件編號（固定以 "CLN-" 為前綴）
    private static func randomCloneSerial() -> String {
        "CLN-\(Int.random(in: 1000...9999))"
    }

    /// 根據當日法規與天數生成一位受檢旅客（50% 應核准、50% 應拒簽，富含邊界陷阱案例，並依違規層級動態附加行賄事件）
    /// - Parameters:
    ///   - regulation: 當日生效的海關動態法規
    ///   - day: 當前執勤天數（決定解鎖哪些高階陷阱題型）
    /// - Returns: 生成完畢且經規則引擎驗證的 `Traveler` 實體
    static func generate(for regulation: DailyRegulation, day: Int = 4) -> Traveler {
        // 隨機決定本題目標為「應核准（true）」或「應拒簽（false）」
        let targetApprove = Bool.random()

        // 嘗試生成符合目標判決（50% 核准 / 50% 拒簽）的陷阱旅客，最多重試 20 次以確保題型品質
        for _ in 0..<20 {
            var candidate = targetApprove
                ? generateApproveCandidate(for: regulation, day: day)
                : generateDenyCandidate(for: regulation, day: day)
            let verdict = CustomsRuleEngine.evaluate(traveler: candidate, regulation: regulation)
            if verdict.shouldApprove == targetApprove {
                // 僅限第 2 天（day >= 2）以上且判定為違規（!verdict.shouldApprove）的旅客，有約 35% 機率觸發行賄事件；合規旅客絕不會行賄
                if day >= 2 && !verdict.shouldApprove && Int.random(in: 1...100) <= 35 {
                    if verdict.violatedLayer.hasPrefix("第一層") {
                        // 觸犯第一層（絕對安全/生理紅線） -> 超高額賄款（450...550），極高稽查風險（+40%）
                        let dialogues = [
                            "「長官，只要閉上眼睛蓋章放行，這筆錢夠你買全套頂級掃描儀，沒人會知道！」",
                            "「別管警報器了！只要閉上眼睛蓋章，這筆錢夠你買全套掃描儀，放我過去！」"
                        ]
                        candidate.bribeOffer = BribeOffer(
                            amount: Int.random(in: 450...550),
                            riskIncrease: 40,
                            dialogue: dialogues.randomElement() ?? dialogues[0]
                        )
                    } else if verdict.violatedLayer.hasPrefix("第二層") {
                        // 觸犯第二層（偽造證件/空箱走私） -> 高額賄款（300...400），高稽查風險（+30%）
                        let dialogues = [
                            "「長官，只是證件系統出錯而已，這點星際幣點數收下別聲張，行個方便吧。」",
                            "「這批貨跟證件只是系統同步延遲，點數收下別聲張，當作沒看到這筆矛盾吧。」"
                        ]
                        candidate.bribeOffer = BribeOffer(
                            amount: Int.random(in: 300...400),
                            riskIncrease: 30,
                            dialogue: dialogues.randomElement() ?? dialogues[0]
                        )
                    } else {
                        // 觸犯第三至六層常規/動態法規 -> 中等賄款（180...260），中低稽查風險（+18%）
                        let dialogues = [
                            "「長官通融一下！我趕著轉乘星艦，一點星際幣請長官喝咖啡，幫我蓋個核准章吧。」",
                            "「臨時改法規誰來得及辦手續？趕著轉乘星艦，一點星際幣請長官喝咖啡！」"
                        ]
                        candidate.bribeOffer = BribeOffer(
                            amount: Int.random(in: 180...260),
                            riskIncrease: 18,
                            dialogue: dialogues.randomElement() ?? dialogues[0]
                        )
                    }
                } else {
                    candidate.bribeOffer = nil
                }
                return candidate
            }
        }

        // 保底安全回退機制：若隨機重試未命中則回傳完全合規的基準旅客（合規旅客絕不會行賄）
        return makeBaselineCompliantTraveler(for: regulation)
    }

    // MARK: - 應核准（Approve）的迷惑性邊界與標準案例
    /// 生成看似可疑但實際符合豁免條款或完全合規的「應核准」候選旅客
    private static func generateApproveCandidate(for regulation: DailyRegulation, day: Int) -> Traveler {
        let base = makeBaselineCompliantTraveler(for: regulation)

        // 根據天數開放不同層級的「看似違規但其實合規」邊界陷阱題型編號
        var availableTraps: [Int] = [1, 2, 3, 4, 5] // Day 1 基礎與第一層、第六層豁免陷阱
        if day >= 2 {
            availableTraps.append(contentsOf: [6, 7, 8, 9]) // Day 2 解鎖第二、三層陷阱
        }
        if day >= 3 {
            availableTraps.append(contentsOf: [10]) // Day 3 解鎖第四層非有機體免疫苗陷阱
        }
        if day >= 4 {
            availableTraps.append(contentsOf: [11, 12, 13]) // Day 4+ 解鎖第五層特殊物品合規與半機械人豁免
        }

        let choice = availableTraps.randomElement() ?? 1

        switch choice {
        case 1:
            // 【第一層邊界陷阱：應核准】體溫高達 50°C 的矽基生命（矽基生命天生高溫，不受體溫上限限制）
            return copy(
                base,
                species: .silicon,
                serialCode: randomNormalSerial(),
                bodyTemperature: Double.random(in: 45.0...54.0)
            )

        case 2:
            // 【第一層邊界陷阱：應核准】輻射值 58~72 mSv 的獵戶座重工區工人（享有 +25 mSv 寬容值，實際上限為 75 mSv）
            guard !regulation.bannedOrigins.contains(.orionIndustrial) else { return base }
            return copy(
                base,
                origin: .orionIndustrial,
                radiationLevel: Double.random(in: (regulation.maxAllowedRadiation + 8.0)...(regulation.maxAllowedRadiation + 22.0))
            )

        case 3:
            // 【第一層邊界陷阱：應核准】氣態能量體（表面數值可能極高，但氣態生命無體溫只看輻射，且輻射在安全範圍內）
            return copy(
                base,
                species: .gasEntity,
                serialCode: randomNormalSerial(),
                bodyTemperature: Double.random(in: 80.0...120.0),
                radiationLevel: Double.random(in: 12.0...(regulation.maxAllowedRadiation - 5.0))
            )

        case 4:
            // 【第六層邊界陷阱：應核准】無入境許可證的太陽系居民（太陽系公民享免簽證待遇）
            guard !regulation.bannedOrigins.contains(.solar) else { return base }
            return copy(
                base,
                origin: .solar,
                hasEntryPermit: false
            )

        case 5:
            // 【第六層邊界陷阱：應核准】無入境許可證的天狼星貿易聯邦商人（天狼星 + 商務貿易目的享免簽待遇）
            guard !regulation.bannedOrigins.contains(.siriusFederation),
                  regulation.restrictedPurpose != .trade else { return base }
            return copy(
                base,
                origin: .siriusFederation,
                purpose: .trade,
                hasEntryPermit: false
            )

        case 6:
            // 【第二層邊界陷阱：應核准】合法的克隆人（證件編號正確以 CLN- 開頭）
            return copy(
                base,
                species: .clone,
                serialCode: randomCloneSerial()
            )

        case 7:
            // 【第二層邊界陷阱：應核准】行李重達 32 kg，但有誠實申報合規物品（非申報 ContrabandItem.none，不構成空箱走私矛盾）
            let safeHeavyItems: [ContrabandItem] = [.liquidMetal, .neuralEraser, .radioactiveIsotope]
                .filter { !regulation.bannedItems.contains($0) }
            guard let item = safeHeavyItems.randomElement() else { return base }
            return copy(
                base,
                declaredItem: item,
                baggageWeight: Double.random(in: 28.0...36.0)
            )

        case 8:
            // 【第三層邊界陷阱：應核准】正統星際外交官持有外交豁免令（即使護照過期、無簽證、來自封鎖星系也可合法放行）
            let riskyOrigin = regulation.bannedOrigins.first ?? .voidExile
            return copy(
                base,
                species: .diplomat,
                serialCode: randomNormalSerial(),
                origin: riskyOrigin,
                purpose: .diplomatic,
                passportExpiryYear: regulation.currentYear - Int.random(in: 1...4),
                hasEntryPermit: false,
                hasDiplomaticImmunity: true
            )

        case 9:
            // 【第三層邊界陷阱：應核准】帶著過期護照、無簽證、甚至來自封鎖區，但「未攜帶任何物品」的難民庇護者
            let riskyOrigin = regulation.bannedOrigins.first ?? .quarantineZone
            return copy(
                base,
                origin: riskyOrigin,
                purpose: .asylum,
                passportExpiryYear: regulation.currentYear - Int.random(in: 1...5),
                hasEntryPermit: false,
                hasDiplomaticImmunity: false,
                declaredItem: ContrabandItem.none,
                baggageWeight: Double.random(in: 5.0...15.0)
            )

        case 10:
            // 【第四層邊界陷阱：應核准】防疫期間「未持有疫苗證明」的非有機體（半機械人 / 矽基生命 / 氣態能量體依法免驗疫苗）
            let nonOrganicSpecies: Species = [.cyborg, .silicon, .gasEntity].randomElement() ?? .cyborg
            return copy(
                base,
                species: nonOrganicSpecies,
                serialCode: randomNormalSerial(),
                hasVaccineCert: false
            )

        case 11:
            // 【第五層邊界陷阱：應核准】半機械人攜帶「液態金屬」（即使今日禁運液態金屬，半機械人維修自用仍可豁免，且第六層證件齊全）
            return copy(
                base,
                species: .cyborg,
                serialCode: randomNormalSerial(),
                declaredItem: .liquidMetal,
                baggageWeight: Double.random(in: 14.0...22.0)
            )

        case 12:
            // 【第五層邊界陷阱：應核准】蟲族工蜂攜帶「蟲后費洛蒙」（只要今日未禁運蟲后費洛蒙即完全合規）
            guard !regulation.bannedItems.contains(.queenPheromone) else { return base }
            return copy(
                base,
                species: .insectoid,
                serialCode: randomNormalSerial(),
                declaredItem: .queenPheromone,
                baggageWeight: Double.random(in: 8.0...18.0)
            )

        case 13:
            // 【第五層邊界陷阱：應核准】以「科學研究」為目的攜帶「暗物質電池」（只要今日未禁運暗物質電池且未限制科研目的即合規）
            guard !regulation.bannedItems.contains(.darkMatter),
                  regulation.restrictedPurpose != .research else { return base }
            return copy(
                base,
                purpose: .research,
                declaredItem: .darkMatter,
                baggageWeight: Double.random(in: 12.0...20.0)
            )

        default:
            return base
        }
    }

    // MARK: - 應拒簽（Deny）的迷惑性邊界與違規案例
    /// 生成觸犯各層級海關法規或連環陷阱的「應拒簽」候選旅客
    private static func generateDenyCandidate(for regulation: DailyRegulation, day: Int) -> Traveler {
        let base = makeBaselineCompliantTraveler(for: regulation)

        // 依天數解鎖對應層級的違規陷阱題型編號
        var availableTraps: [Int] = [1, 2, 3, 4, 5, 6, 7] // Day 1: 第一層紅線與第六層基礎證件違規
        if day >= 2 {
            availableTraps.append(contentsOf: [8, 9, 10, 11, 12]) // Day 2: 第二層偽造矛盾與第三層難民帶物/假特權
        }
        if day >= 3 {
            availableTraps.append(contentsOf: [13, 14]) // Day 3: 第四層封鎖星系與有機體無疫苗
        }
        if day >= 4 {
            availableTraps.append(contentsOf: [15, 16, 17, 18, 19]) // Day 4+: 第四層暫停目的、第五層交叉限制與半機械人過期陷阱
        }

        let choice = availableTraps.randomElement() ?? 1

        switch choice {
        case 1:
            // 【第一層違規】攜帶一級違禁品（異星孢子或量子走私核心），連持有外交豁免令的外交官都必須拒簽！
            let contraband: ContrabandItem = Bool.random() ? .alienSpore : .quantumCore
            let isDiplomatTrap = (day >= 2 && Bool.random())
            return copy(
                base,
                species: isDiplomatTrap ? .diplomat : base.species,
                serialCode: randomNormalSerial(),
                hasDiplomaticImmunity: isDiplomatTrap,
                declaredItem: contraband
            )

        case 2:
            // 【第一層違規】氣態能量體高能輻射超標（> 50 mSv）
            return copy(
                base,
                species: .gasEntity,
                serialCode: randomNormalSerial(),
                radiationLevel: Double.random(in: (regulation.maxAllowedRadiation + 4.0)...88.0)
            )

        case 3:
            // 【第一層違規】非矽基、非氣態生命體溫超標（連外交官與難民發燒也不可豁免）
            let feverSpecies: Species = [.human, .cyborg, .diplomat, .insectoid, .shapeshifter, .clone].randomElement() ?? .human
            let code = feverSpecies == .clone ? randomCloneSerial() : randomNormalSerial()
            return copy(
                base,
                species: feverSpecies,
                serialCode: code,
                hasDiplomaticImmunity: feverSpecies == .diplomat,
                bodyTemperature: Double.random(in: (regulation.maxAllowedTemp + 0.6)...42.5)
            )

        case 4:
            // 【第一層違規】非獵戶座居民輻射值 55~72 mSv（測試玩家是否誤以為所有人都享有 75 mSv 寬容值的陷阱）
            let nonOrionOrigins = StarSystem.allCases.filter { $0 != .orionIndustrial && !regulation.bannedOrigins.contains($0) }
            return copy(
                base,
                origin: nonOrionOrigins.randomElement() ?? .solar,
                radiationLevel: Double.random(in: (regulation.maxAllowedRadiation + 5.0)...(regulation.maxAllowedRadiation + 22.0))
            )

        case 5:
            // 【第一層違規】獵戶座重工區居民輻射值超過 75 mSv（連 +25 mSv 寬容值都救不了）
            return copy(
                base,
                origin: .orionIndustrial,
                radiationLevel: Double.random(in: (regulation.maxAllowedRadiation + 26.5)...98.0)
            )

        case 6:
            // 【第六層違規】護照已過期（非外交特權、非難民庇護的一般旅客）
            return copy(
                base,
                passportExpiryYear: regulation.currentYear - Int.random(in: 1...6)
            )

        case 7:
            // 【第六層違規】天狼星貿易聯邦居民「無簽證」，但入境目的不是商務貿易（例如觀光旅遊，不適用商務免簽）
            return copy(
                base,
                origin: .siriusFederation,
                purpose: .tourism,
                hasEntryPermit: false
            )

        case 8:
            // 【第二層違規】偽造外交豁免令：非外交官種族（如變形者、地球人）卻持有外交豁免令
            let fakeSpecies: Species = [.shapeshifter, .human, .cyborg, .clone].randomElement() ?? .shapeshifter
            let code = fakeSpecies == .clone ? randomCloneSerial() : randomNormalSerial()
            return copy(
                base,
                species: fakeSpecies,
                serialCode: code,
                hasDiplomaticImmunity: true
            )

        case 9:
            // 【第二層違規】非法克隆體：種族為克隆人，但證件編號不是 CLN- 開頭（例如 ID-8842）
            return copy(
                base,
                species: .clone,
                serialCode: randomNormalSerial()
            )

        case 10:
            // 【第二層違規】疑似空箱走私：申報「無物品 (ContrabandItem.none)」，但行李重量達 28.5~38.0 kg（> 25 kg）
            return copy(
                base,
                species: .human,
                serialCode: randomNormalSerial(),
                declaredItem: ContrabandItem.none,
                baggageWeight: Double.random(in: 28.5...38.0)
            )

        case 11:
            // 【第三層違規】難民庇護者卻攜帶特殊管制物品（難民禁止攜帶任何非 .none 物品）
            let carriedItem: ContrabandItem = [.liquidMetal, .darkMatter, .neuralEraser, .radioactiveIsotope].randomElement() ?? .liquidMetal
            return copy(
                base,
                purpose: .asylum,
                declaredItem: carriedItem,
                baggageWeight: Double.random(in: 12.0...22.0)
            )

        case 12:
            // 【第六層陷阱違規】星際外交官「未持有」外交豁免令，且護照過期或無簽證（無豁免令即須按一般法規受檢）
            return copy(
                base,
                species: .diplomat,
                serialCode: randomNormalSerial(),
                origin: .andromeda,
                purpose: .diplomatic,
                passportExpiryYear: regulation.currentYear - 2,
                hasEntryPermit: false,
                hasDiplomaticImmunity: false
            )

        case 13:
            // 【第四層違規】來自今日封鎖星系的一般旅客
            if let bannedOrigin = regulation.bannedOrigins.randomElement() {
                return copy(base, origin: bannedOrigin)
            }
            return copy(base, passportExpiryYear: regulation.currentYear - 1)

        case 14:
            // 【第四層違規】防疫期間，有機生命體（地球人、變形者、蟲族、克隆人等）未持有疫苗證明
            if regulation.requireVaccine {
                let organicSpecies: Species = [.human, .insectoid, .shapeshifter, .clone].randomElement() ?? .human
                let code = organicSpecies == .clone ? randomCloneSerial() : randomNormalSerial()
                return copy(
                    base,
                    species: organicSpecies,
                    serialCode: code,
                    hasVaccineCert: false
                )
            }
            return copy(base, passportExpiryYear: regulation.currentYear - 1)

        case 15:
            // 【第四層違規】入境目的為今日緊急暫停受理的目的
            if let restricted = regulation.restrictedPurpose {
                return copy(base, purpose: restricted)
            }
            return copy(base, passportExpiryYear: regulation.currentYear - 1)

        case 16:
            // 【第五層違規】非蟲族工蜂攜帶「蟲后費洛蒙」
            let nonInsectSpecies: Species = [.human, .cyborg, .silicon, .shapeshifter].randomElement() ?? .human
            return copy(
                base,
                species: nonInsectSpecies,
                serialCode: randomNormalSerial(),
                declaredItem: .queenPheromone,
                baggageWeight: Double.random(in: 10.0...20.0)
            )

        case 17:
            // 【第五層違規】非「科學研究」目的（例如商務貿易或觀光旅遊）攜帶「暗物質電池」
            let wrongPurpose: TravelPurpose = [.tourism, .trade].filter { $0 != regulation.restrictedPurpose }.randomElement() ?? .tourism
            return copy(
                base,
                purpose: wrongPurpose,
                declaredItem: .darkMatter,
                baggageWeight: Double.random(in: 10.0...20.0)
            )

        case 18:
            // 【第五層違規】攜帶今日臨時禁運物品（若為液態金屬則刻意選非半機械人，避免觸發維修豁免）
            if let bannedItem = regulation.bannedItems.randomElement() {
                let chosenSpecies: Species = (bannedItem == .liquidMetal) ? .human : base.species
                let code = chosenSpecies == .clone ? randomCloneSerial() : randomNormalSerial()
                let chosenPurpose: TravelPurpose = (bannedItem == .darkMatter) ? .research : base.purpose
                return copy(
                    base,
                    species: chosenSpecies,
                    serialCode: code,
                    purpose: chosenPurpose,
                    declaredItem: bannedItem,
                    baggageWeight: Double.random(in: 10.0...20.0)
                )
            }
            return copy(base, passportExpiryYear: regulation.currentYear - 2)

        case 19:
            // 【第五層+第六層連環陷阱：應拒簽】半機械人攜帶液態金屬（第五層豁免），但護照已過期（第六層攔截）！
            return copy(
                base,
                species: .cyborg,
                serialCode: randomNormalSerial(),
                passportExpiryYear: regulation.currentYear - Int.random(in: 1...3),
                declaredItem: .liquidMetal,
                baggageWeight: Double.random(in: 12.0...20.0)
            )

        default:
            return copy(base, passportExpiryYear: regulation.currentYear - 1)
        }
    }

    // MARK: - 建立完全合規的基準旅客
    /// 建立一位通過全部六層檢定的完全合規基準旅客，作為各類陷阱題型的改裝基底
    private static func makeBaselineCompliantTraveler(for regulation: DailyRegulation) -> Traveler {
        let name = names.randomElement() ?? "艾克斯 (Axel)"
        let safeSpeciesPool: [Species] = [.human, .cyborg, .silicon, .insectoid, .shapeshifter, .clone]
        let species = safeSpeciesPool.randomElement() ?? .human
        let serialCode = species == .clone ? randomCloneSerial() : randomNormalSerial()

        // 挑選今日未遭封鎖的安全來源星系
        let safeOrigins = StarSystem.allCases.filter { !regulation.bannedOrigins.contains($0) }
        let origin = safeOrigins.randomElement() ?? .solar

        // 挑選非特權且今日未受限制的一般入境目的
        let safePurposes = TravelPurpose.allCases.filter {
            $0 != .asylum && $0 != .diplomatic && $0 != regulation.restrictedPurpose
        }
        let purpose = safePurposes.randomElement() ?? .tourism

        return Traveler(
            name: name,
            serialCode: serialCode,
            species: species,
            origin: origin,
            purpose: purpose,
            passportExpiryYear: Int.random(in: regulation.currentYear...(regulation.currentYear + 6)),
            hasEntryPermit: true,
            hasDiplomaticImmunity: false,
            hasVaccineCert: true,
            declaredItem: ContrabandItem.none,
            baggageWeight: Double.random(in: 6.0...22.0),
            bodyTemperature: Double.random(in: 36.1...37.4),
            radiationLevel: Double.random(in: 8.0...35.0)
        )
    }

    // MARK: - 輔助複製並覆寫特定屬性
    /// 複製基準旅客資料並覆寫指定的屬性欄位，方便快速構造單一或複合陷阱案例
    private static func copy(
        _ base: Traveler,
        species: Species? = nil,
        serialCode: String? = nil,
        origin: StarSystem? = nil,
        purpose: TravelPurpose? = nil,
        passportExpiryYear: Int? = nil,
        hasEntryPermit: Bool? = nil,
        hasDiplomaticImmunity: Bool? = nil,
        hasVaccineCert: Bool? = nil,
        declaredItem: ContrabandItem? = nil,
        baggageWeight: Double? = nil,
        bodyTemperature: Double? = nil,
        radiationLevel: Double? = nil
    ) -> Traveler {
        Traveler(
            name: base.name,
            serialCode: serialCode ?? base.serialCode,
            species: species ?? base.species,
            origin: origin ?? base.origin,
            purpose: purpose ?? base.purpose,
            passportExpiryYear: passportExpiryYear ?? base.passportExpiryYear,
            hasEntryPermit: hasEntryPermit ?? base.hasEntryPermit,
            hasDiplomaticImmunity: hasDiplomaticImmunity ?? base.hasDiplomaticImmunity,
            hasVaccineCert: hasVaccineCert ?? base.hasVaccineCert,
            declaredItem: declaredItem ?? base.declaredItem,
            baggageWeight: baggageWeight ?? base.baggageWeight,
            bodyTemperature: bodyTemperature ?? base.bodyTemperature,
            radiationLevel: radiationLevel ?? base.radiationLevel,
            bribeOffer: base.bribeOffer
        )
    }
}
