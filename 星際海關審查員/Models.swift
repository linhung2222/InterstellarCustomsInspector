import Foundation

/// 旅客物種分類列舉（共 8 種，包含是否為有機生命體的判定邏輯）
enum Species: String, CaseIterable, Identifiable {
    /// 地球人（有機體）
    case human
    /// 半機械人（非有機體，攜帶液態金屬享維修自用豁免）
    case cyborg
    /// 矽基生命（非有機體，天生高溫享體溫上限豁免）
    case silicon
    /// 星際外交官（有機體，持有有效外交豁免令時可享特權放行）
    case diplomat
    /// 蟲族工蜂（有機體，唯一可合法攜帶蟲后費洛蒙的物種）
    case insectoid
    /// 氣態能量體（非有機體，無體溫概念，僅需檢定高能輻射值）
    case gasEntity
    /// 變形者（有機體，常偽造身分或持有假特權）
    case shapeshifter
    /// 克隆人（有機體，證件編號必須以 "CLN-" 為前綴）
    case clone

    /// 遵循 Identifiable 協定的唯一識別碼
    var id: String { rawValue }

    /// 是否為有機生命體（星際防疫啟動期間，所有有機體皆須出示疫苗證明）
    var isOrganic: Bool {
        switch self {
        case .human, .diplomat, .insectoid, .shapeshifter, .clone:
            return true
        case .cyborg, .silicon, .gasEntity:
            return false
        }
    }

    /// 完整顯示名稱（包含繁體中文與英文對照）
    var displayName: String {
        switch self {
        case .human:
            return "地球人 (Human)"
        case .cyborg:
            return "半機械人 (Cyborg)"
        case .silicon:
            return "矽基生命 (Silicon)"
        case .diplomat:
            return "星際外交官 (Diplomat)"
        case .insectoid:
            return "蟲族工蜂 (Insectoid)"
        case .gasEntity:
            return "氣態能量體 (Gas Entity)"
        case .shapeshifter:
            return "變形者 (Shapeshifter)"
        case .clone:
            return "克隆人 (Clone)"
        }
    }

    /// 簡短中文名稱（用於護照網格與訊息提示）
    var shortName: String {
        switch self {
        case .human: return "地球人"
        case .cyborg: return "半機械人"
        case .silicon: return "矽基生命"
        case .diplomat: return "星際外交官"
        case .insectoid: return "蟲族工蜂"
        case .gasEntity: return "氣態能量體"
        case .shapeshifter: return "變形者"
        case .clone: return "克隆人"
        }
    }

    /// 有機體分類標籤文字（用於介面膠囊標籤顯示）
    var organicLabel: String {
        isOrganic ? "有機體" : "非有機體"
    }

    /// 對應的 SF Symbols 系統圖示名稱
    var symbolName: String {
        switch self {
        case .human: return "person.fill"
        case .cyborg: return "cpu.fill"
        case .silicon: return "hexagon.fill"
        case .diplomat: return "crown.fill"
        case .insectoid: return "ant.fill"
        case .gasEntity: return "sparkles"
        case .shapeshifter: return "theatermasks.fill"
        case .clone: return "person.2.crop.square.stack.fill"
        }
    }
}

/// 旅客來源星系分類列舉（共 8 個星系）
enum StarSystem: String, CaseIterable, Identifiable, Hashable {
    /// 太陽系（公民享永久免簽證入境待遇）
    case solar
    /// 仙女座星系
    case andromeda
    /// 克卜勒星系
    case kepler
    /// 第七隔離區
    case quarantineZone
    /// 天狼星貿易聯邦（公民以「商務貿易」目的入境時享免簽待遇）
    case siriusFederation
    /// 獵戶座重工區（居民因工作環境享有 +25 mSv 的輻射劑量寬容額度）
    case orionIndustrial
    /// 澤塔蟲巢星域
    case zetaHive
    /// 虛空流放帶
    case voidExile

    /// 遵循 Identifiable 協定的唯一識別碼
    var id: String { rawValue }

    /// 完整星系顯示名稱（含中英文對照）
    var displayName: String {
        switch self {
        case .solar:
            return "太陽系 (Solar)"
        case .andromeda:
            return "仙女座星系 (Andromeda)"
        case .kepler:
            return "克卜勒星系 (Kepler)"
        case .quarantineZone:
            return "第七隔離區 (Sector-7)"
        case .siriusFederation:
            return "天狼星貿易聯邦 (Sirius)"
        case .orionIndustrial:
            return "獵戶座重工區 (Orion)"
        case .zetaHive:
            return "澤塔蟲巢星域 (Zeta Hive)"
        case .voidExile:
            return "虛空流放帶 (Void Exile)"
        }
    }

    /// 簡短中文星系名稱
    var shortName: String {
        switch self {
        case .solar: return "太陽系"
        case .andromeda: return "仙女座星系"
        case .kepler: return "克卜勒星系"
        case .quarantineZone: return "第七隔離區"
        case .siriusFederation: return "天狼星貿易聯邦"
        case .orionIndustrial: return "獵戶座重工區"
        case .zetaHive: return "澤塔蟲巢星域"
        case .voidExile: return "虛空流放帶"
        }
    }
}

/// 旅客申報攜帶物品分類列舉（共 8 種）
enum ContrabandItem: String, CaseIterable, Identifiable, Hashable {
    /// 未攜帶任何特殊管制品（若行李重量超過 25 kg 則構成空箱走私矛盾）
    case none
    /// 液態金屬（即使當日公告禁運，半機械人攜帶仍屬維修自用可豁免）
    case liquidMetal
    /// 暗物質電池（僅限「科學研究」目的之旅客攜帶）
    case darkMatter
    /// 異星孢子（第一層一級星際絕對違禁品，任何人皆不可攜帶）
    case alienSpore
    /// 記憶抹除器（受每日動態禁運令管制的一般特殊物品）
    case neuralEraser
    /// 蟲后費洛蒙（僅限「蟲族工蜂」物種攜帶）
    case queenPheromone
    /// 輻射同位素（受每日動態禁運令管制的一般特殊物品）
    case radioactiveIsotope
    /// 量子走私核心（第一層一級星際絕對違禁品，任何人皆不可攜帶）
    case quantumCore

    /// 遵循 Identifiable 協定的唯一識別碼
    var id: String { rawValue }

    /// 完整物品顯示名稱（含中英文對照）
    var displayName: String {
        switch self {
        case .none:
            return "無 (None)"
        case .liquidMetal:
            return "液態金屬 (Liquid Metal)"
        case .darkMatter:
            return "暗物質電池 (Dark Matter)"
        case .alienSpore:
            return "異星孢子 (Alien Spore)"
        case .neuralEraser:
            return "記憶抹除器 (Neural Eraser)"
        case .queenPheromone:
            return "蟲后費洛蒙 (Queen Pheromone)"
        case .radioactiveIsotope:
            return "輻射同位素 (Isotope)"
        case .quantumCore:
            return "量子走私核心 (Quantum Core)"
        }
    }

    /// 簡短中文物品名稱
    var shortName: String {
        switch self {
        case .none: return "無"
        case .liquidMetal: return "液態金屬"
        case .darkMatter: return "暗物質電池"
        case .alienSpore: return "異星孢子"
        case .neuralEraser: return "記憶抹除器"
        case .queenPheromone: return "蟲后費洛蒙"
        case .radioactiveIsotope: return "輻射同位素"
        case .quantumCore: return "量子走私核心"
        }
    }

    /// 是否屬於第一層一級星際絕對違禁品（觸發最高優先級安全紅線，外交官亦不可豁免）
    var isLevelOneContraband: Bool {
        self == .alienSpore || self == .quantumCore
    }
}

/// 旅客入境目的分類列舉（共 5 種）
enum TravelPurpose: String, CaseIterable, Identifiable, Hashable {
    /// 觀光旅遊
    case tourism
    /// 商務貿易（搭配天狼星貿易聯邦國籍可享免簽待遇）
    case trade
    /// 外交出使
    case diplomatic
    /// 科學研究（唯一可合法攜帶暗物質電池的入境目的）
    case research
    /// 難民庇護（未攜帶任何特殊物品時，可依人道條款豁免封鎖區、簽證與過期護照限制）
    case asylum

    /// 遵循 Identifiable 協定的唯一識別碼
    var id: String { rawValue }

    /// 完整入境目的顯示名稱（含中英文對照）
    var displayName: String {
        switch self {
        case .tourism:
            return "觀光旅遊 (Tourism)"
        case .trade:
            return "商務貿易 (Trade)"
        case .diplomatic:
            return "外交出使 (Diplomatic)"
        case .research:
            return "科學研究 (Research)"
        case .asylum:
            return "難民庇護 (Asylum)"
        }
    }

    /// 簡短中文入境目的名稱
    var shortName: String {
        switch self {
        case .tourism: return "觀光旅遊"
        case .trade: return "商務貿易"
        case .diplomatic: return "外交出使"
        case .research: return "科學研究"
        case .asylum: return "難民庇護"
        }
    }

    /// 對應的 SF Symbols 系統圖示名稱
    var symbolName: String {
        switch self {
        case .tourism: return "camera.fill"
        case .trade: return "shippingbox.fill"
        case .diplomatic: return "building.columns.fill"
        case .research: return "atom"
        case .asylum: return "lifepreserver.fill"
        }
    }
}

/// 違規旅客私下傳送的加密行賄提案資料結構
struct BribeOffer: Equatable {
    /// 賄賂提供的星際幣金額（依違規嚴重度介於 180 ~ 550 之間）
    let amount: Int
    /// 收賄後增加的星際廉政署稽查風險百分比（例如 18% ~ 40%）
    let riskIncrease: Int
    /// 旅客私下傳送的加密行賄台詞（臺灣繁體中文）
    let dialogue: String
}

/// 旅客完整電子護照與生物感測資料結構
struct Traveler: Identifiable, Equatable {
    /// 旅客唯一識別碼（用於觸發畫面切換動畫與狀態識別）
    let id: UUID
    /// 旅客姓名（含中英文名稱）
    let name: String
    /// 證件編號（例如 "ID-4821"，克隆人合法編號須為 "CLN-" 開頭）
    let serialCode: String
    /// 旅客物種分類
    let species: Species
    /// 旅客來源星系
    let origin: StarSystem
    /// 申請入境目的
    let purpose: TravelPurpose
    /// 護照到期星曆年份（小於當日法規年份即為過期）
    let passportExpiryYear: Int
    /// 是否持有有效入境許可簽證
    let hasEntryPermit: Bool
    /// 是否持有外交豁免令（僅星際外交官持有才算合法）
    let hasDiplomaticImmunity: Bool
    /// 是否持有星際疫苗接種證明
    let hasVaccineCert: Bool
    /// 申報攜帶的特殊物品
    let declaredItem: ContrabandItem
    /// 隨身行李重量（單位：公斤 kg，申報無物品卻超過 25 kg 視為走私）
    let baggageWeight: Double
    /// 紅外線感測體溫（單位：攝氏 °C）
    let bodyTemperature: Double
    /// 高能輻射感測劑量（單位：毫西弗 mSv）
    let radiationLevel: Double
    /// 加密行賄提案（若為 nil 代表該旅客未行賄）
    var bribeOffer: BribeOffer? = nil

    /// 初始化旅客完整護照與生理數據
    init(
        id: UUID = UUID(),
        name: String,
        serialCode: String,
        species: Species,
        origin: StarSystem,
        purpose: TravelPurpose,
        passportExpiryYear: Int,
        hasEntryPermit: Bool,
        hasDiplomaticImmunity: Bool,
        hasVaccineCert: Bool,
        declaredItem: ContrabandItem,
        baggageWeight: Double,
        bodyTemperature: Double,
        radiationLevel: Double,
        bribeOffer: BribeOffer? = nil
    ) {
        self.id = id
        self.name = name
        self.serialCode = serialCode
        self.species = species
        self.origin = origin
        self.purpose = purpose
        self.passportExpiryYear = passportExpiryYear
        self.hasEntryPermit = hasEntryPermit
        self.hasDiplomaticImmunity = hasDiplomaticImmunity
        self.hasVaccineCert = hasVaccineCert
        self.declaredItem = declaredItem
        self.baggageWeight = baggageWeight
        self.bodyTemperature = bodyTemperature
        self.radiationLevel = radiationLevel
        self.bribeOffer = bribeOffer
    }
}

/// 每日動態海關法規資料結構
struct DailyRegulation: Equatable {
    /// 當前星曆年份（預設為 3026 年，用於核對護照是否過期）
    var currentYear: Int = 3026
    /// 今日緊急封鎖的來源星系集合（第四層法規）
    var bannedOrigins: Set<StarSystem> = []
    /// 今日臨時公告禁運的物品集合（第五層法規）
    var bannedItems: Set<ContrabandItem> = []
    /// 今日緊急暫停受理的入境目的（第四層法規，nil 表示不限制）
    var restrictedPurpose: TravelPurpose? = nil
    /// 今日是否啟動星際強制檢疫（若為 true，所有有機體必須持有疫苗證明）
    var requireVaccine: Bool = false
    /// 標準生理體溫容許上限（預設 38.5°C，矽基生命豁免、氣態體不適用）
    var maxAllowedTemp: Double = 38.5
    /// 標準輻射劑量容許上限（預設 50.0 mSv，獵戶座重工區居民可再放寬 +25.0 mSv）
    var maxAllowedRadiation: Double = 50.0
}

/// 海關規則引擎審查判決結果
struct InspectionVerdict: Equatable {
    /// 標準答案是否應核准放行（true 為應核准，false 為應拒簽）
    let shouldApprove: Bool
    /// 判定放行或拒簽的詳細法規理由說明
    let reason: String
    /// 決定此判決結果的法規優先層級名稱（第一層至第六層）
    let violatedLayer: String
}

/// 海關終端機升級道具與消耗品列舉（於每日結算商店使用積分採購）
enum UpgradeItem: String, CaseIterable, Identifiable, Hashable {
    /// 自動體溫與輻射警報器（自動標記第一層生理紅線異常）
    case bioScanner
    /// 偽造編號與邏輯掃描儀（自動偵測第二層證件矛盾與空箱走私）
    case forgeryDetector
    /// 護照效期核對模組（自動比對護照到期年份是否過期）
    case expiryChecker
    /// 違禁品與禁區雷達（自動標示一級違禁品、封鎖星系與禁運物品）
    case contrabandRadar
    /// 人事失誤紀錄抹除（消耗品，立即消除 1 顆失誤紅燈）
    case strikeRepair

    /// 遵循 Identifiable 協定的唯一識別碼
    var id: String { rawValue }

    /// 裝備或道具的中文名稱
    var title: String {
        switch self {
        case .bioScanner:
            return "自動體溫與輻射警報器"
        case .forgeryDetector:
            return "偽造編號與邏輯掃描儀"
        case .expiryChecker:
            return "護照效期核對模組"
        case .contrabandRadar:
            return "違禁品與禁區雷達"
        case .strikeRepair:
            return "人事失誤紀錄抹除"
        }
    }

    /// 裝備或道具的功能詳細說明
    var description: String {
        switch self {
        case .bioScanner:
            return "自動偵測第一層生理紅線（已內建矽基高溫豁免、氣態體純輻射判定與獵戶座 +25 mSv 寬容值），異常時在護照上亮紅燈警告。"
        case .forgeryDetector:
            return "自動偵測第二層邏輯矛盾（克隆人缺少 CLN- 前綴、非外交官持豁免令、申報無物品但行李超過 25 kg），異常時標示黃色警告。"
        case .expiryChecker:
            return "自動比對護照到期年份是否小於當前年份，過期直接反紅閃爍提示。"
        case .contrabandRadar:
            return "自動標記一級違禁品、今日封鎖星系與今日禁運物品（會自動排除半機械人攜帶液態金屬的合法例外）。"
        case .strikeRepair:
            return "立即清除 1 顆失誤警告紅燈（僅在目前失誤次數大於 0 時可購買，可重複購買）。"
        }
    }

    /// 購買所需的星際幣（Credits）價格
    var cost: Int {
        switch self {
        case .bioScanner:
            return 250
        case .forgeryDetector:
            return 350
        case .expiryChecker:
            return 200
        case .contrabandRadar:
            return 400
        case .strikeRepair:
            return 300
        }
    }

    /// 對應的 SF Symbols 圖示名稱
    var iconName: String {
        switch self {
        case .bioScanner:
            return "waveform.path.ecg.rectangle.fill"
        case .forgeryDetector:
            return "qrcode.viewfinder"
        case .expiryChecker:
            return "calendar.badge.exclamationmark"
        case .contrabandRadar:
            return "dot.radiowaves.left.and.right"
        case .strikeRepair:
            return "wrench.and.screwdriver.fill"
        }
    }

    /// 是否為單次消耗品（true 代表可重複購買的消耗品，false 代表永久安裝的硬體模組）
    var isConsumable: Bool {
        switch self {
        case .strikeRepair:
            return true
        case .bioScanner, .forgeryDetector, .expiryChecker, .contrabandRadar:
            return false
        }
    }
}

/// 遊戲結束（Game Over）原因列舉
enum GameOverReason: Equatable {
    /// 審查失誤次數累積達 3 次遭總署解僱
    case tooManyStrikes
    /// 貪污收賄遭星際廉政署查獲逮捕並撤職
    case firedForCorruption
}

/// 星際廉政署每日結算抽查結果列舉
enum AuditResult: Equatable {
    /// 今日稽查風險為 0%，未啟動抽查
    case notTriggered
    /// 廉政署啟動抽查，但未查獲實證，驚險過關
    case fined(penalty: Int)
    /// 廉政署抽查完畢，驚險過關（未抽中違規帳目）
    case passed
    /// 罪證確鑿（高風險下遭查獲），立即撤職並觸發遊戲結束
    case arrested
}

/// 每日值勤結算報告資料結構（供每日結算畫面顯示明細）
struct DailySummaryReport: Equatable {
    /// 當日審查正確人數
    let correctCount: Int
    /// 當日審查失誤次數
    let mistakeCount: Int
    /// 當日基礎審查收入
    let baseReward: Int
    /// 全勤零失誤獎金（當日無失誤可得 150 星際幣）
    let perfectShiftBonus: Int
    /// 廉潔聲望津貼（聲望達 30 或 60 時額外核發的津貼）
    let reputationBonus: Int
    /// 星際廉政署抽查結果
    let auditResult: AuditResult
    /// 當日總獲得積分與星際幣小計
    let totalEarned: Int
}
