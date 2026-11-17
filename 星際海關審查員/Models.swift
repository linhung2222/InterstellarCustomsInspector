import Foundation

/// 旅客物種分類（共 8 種，含是否為有機體判定）
enum Species: String, CaseIterable, Identifiable {
    case human
    case cyborg
    case silicon
    case diplomat
    case insectoid
    case gasEntity
    case shapeshifter
    case clone

    var id: String { rawValue }

    /// 是否為有機生命體（防疫期間須出示疫苗證明）
    var isOrganic: Bool {
        switch self {
        case .human, .diplomat, .insectoid, .shapeshifter, .clone:
            return true
        case .cyborg, .silicon, .gasEntity:
            return false
        }
    }

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

    var organicLabel: String {
        isOrganic ? "有機體" : "非有機體"
    }

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

/// 來源星系分類（共 8 個星系）
enum StarSystem: String, CaseIterable, Identifiable, Hashable {
    case solar
    case andromeda
    case kepler
    case quarantineZone
    case siriusFederation
    case orionIndustrial
    case zetaHive
    case voidExile

    var id: String { rawValue }

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

/// 申報物品分類（共 8 種）
enum ContrabandItem: String, CaseIterable, Identifiable, Hashable {
    case none
    case liquidMetal
    case darkMatter
    case alienSpore
    case neuralEraser
    case queenPheromone
    case radioactiveIsotope
    case quantumCore

    var id: String { rawValue }

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

    /// 是否屬於第一層一級星際絕對違禁品
    var isLevelOneContraband: Bool {
        self == .alienSpore || self == .quantumCore
    }
}

/// 入境目的分類（共 5 種）
enum TravelPurpose: String, CaseIterable, Identifiable, Hashable {
    case tourism
    case trade
    case diplomatic
    case research
    case asylum

    var id: String { rawValue }

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

    var shortName: String {
        switch self {
        case .tourism: return "觀光旅遊"
        case .trade: return "商務貿易"
        case .diplomatic: return "外交出使"
        case .research: return "科學研究"
        case .asylum: return "難民庇護"
        }
    }

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

/// 旅客完整電子護照與生物感測資料
struct Traveler: Identifiable, Equatable {
    let id: UUID
    let name: String
    let serialCode: String
    let species: Species
    let origin: StarSystem
    let purpose: TravelPurpose
    let passportExpiryYear: Int
    let hasEntryPermit: Bool
    let hasDiplomaticImmunity: Bool
    let hasVaccineCert: Bool
    let declaredItem: ContrabandItem
    let baggageWeight: Double
    let bodyTemperature: Double
    let radiationLevel: Double

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
        radiationLevel: Double
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
    }
}

/// 每日動態海關法規
struct DailyRegulation: Equatable {
    var currentYear: Int = 3026
    var bannedOrigins: Set<StarSystem> = []
    var bannedItems: Set<ContrabandItem> = []
    var restrictedPurpose: TravelPurpose? = nil
    var requireVaccine: Bool = false
    var maxAllowedTemp: Double = 38.5
    var maxAllowedRadiation: Double = 50.0
}

/// 海關審查判決結果
struct InspectionVerdict: Equatable {
    let shouldApprove: Bool
    let reason: String
    let violatedLayer: String
}
