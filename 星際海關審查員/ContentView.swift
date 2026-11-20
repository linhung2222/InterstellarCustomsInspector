import SwiftUI

/// 《星際海關審查員》主遊戲畫面：整合頂部狀態列、今日緊急指令速報、旅客電子護照終端機、加密行賄面板與裁決控制區
struct ContentView: View {
    /// 遊戲核心狀態與邏輯控制器
    @State private var viewModel = GameViewModel()
    /// 控制是否彈出「星際海關法規手冊」視窗
    @State private var isShowingRulebook = false
    /// 控制高稽查風險（>= 50%）時的紅色膠囊呼吸閃爍動畫狀態
    @State private var isAuditWarningBlinking = false

    // MARK: - 科幻終端機主題配色定義
    /// 終端機底層深色背景
    private let terminalBackground = Color(red: 0.03, green: 0.05, blue: 0.09)
    /// 資訊卡片深藍灰底色
    private let cardBackground = Color(red: 0.07, green: 0.11, blue: 0.17)
    /// 霓虹青色（主框線、科技標題、物種圖示）
    private let neonCyan = Color(red: 0.00, green: 0.90, blue: 0.96)
    /// 霓虹琥珀金（分數、警告提示、行賄通訊框線）
    private let neonAmber = Color(red: 1.00, green: 0.73, blue: 0.16)
    /// 霓虹警示紅（拒簽按鈕、違規警報、失誤紅燈）
    private let neonRed = Color(red: 1.00, green: 0.27, blue: 0.36)
    /// 霓虹翠綠色（核准按鈕、星際幣餘額、合規狀態）
    private let neonGreen = Color(red: 0.15, green: 0.92, blue: 0.55)
    /// 霓虹紫羅蘭（非有機體標籤、檢舉按鈕、暫停目的高亮）
    private let neonPurple = Color(red: 0.72, green: 0.45, blue: 1.00)
    /// 暗金警告色（私下收賄按鈕漸層）
    private let darkGoldWarning = Color(red: 0.88, green: 0.65, blue: 0.12)

    /// 主畫面視圖結構
    var body: some View {
        ZStack {
            // 全域深色終端機背景
            terminalBackground
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 1. 頂部狀態列（Day、Score、Credits、3 顆失誤紅燈、聲望、稽查風險、法規手冊按鈕）
                topStatusBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 2. 今日速報橫幅（封鎖星系、禁運物品、暫停目的、防疫狀態）
                        dailyDirectiveBanner

                        // 3. 中央電子護照終端機（雙欄網格呈現完整旅客 12 項數據與硬體掃描警示）
                        travelerPassportTerminal

                        // 3.5 加密行賄對話面板（當違規旅客提出行賄時於電子護照下方動態滑出）
                        if let offer = viewModel.currentTraveler.bribeOffer {
                            encryptedBribePanel(offer: offer)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 2)
                    .animation(.spring(duration: 0.35), value: viewModel.currentTraveler.id)
                }

                // 4. 底部判決區（上一題對錯原因 + 觸發層級 + 拒簽/核准按鈕）
                bottomVerdictSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // 5. Game Over 結算遮罩（當累積 3 次失誤或貪污遭逮捕時覆蓋全畫面）
            if viewModel.isGameOver {
                gameOverOverlay
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 啟動高稽查風險膠囊的永久呼吸閃爍動畫
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                isAuditWarningBlinking = true
            }
        }
        // 彈出星際海關法規手冊視窗
        .sheet(isPresented: $isShowingRulebook) {
            RulebookSheetView(
                regulation: viewModel.currentRegulation,
                day: viewModel.day
            )
        }
        // 彈出每日結算與終端機升級商店視窗（禁止手勢下拉關閉以確保完成跨日流程）
        .sheet(isPresented: $viewModel.isShowingDailySummary) {
            DailySummaryShopView(viewModel: viewModel)
                .interactiveDismissDisabled(true)
        }
    }

    // MARK: - 1. 頂部狀態列
    /// 顯示海關部門名稱、已安裝模組圖示、當日配額、天數、積分、星際幣、失誤紅燈、法規手冊按鈕與聲望/風險膠囊列
    private var topStatusBar: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .foregroundStyle(neonCyan)
                    Text("STARPORT BORDER CONTROL: DEEP SECTOR")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(neonCyan)
                        .lineLimit(1)
                }
                Spacer()

                // 已安裝永久掃描裝備迷你圖示列（亮青色代表已安裝啟用）
                HStack(spacing: 5) {
                    ForEach(UpgradeItem.allCases.filter { !$0.isConsumable }) { item in
                        let isEquipped = viewModel.purchasedUpgrades.contains(item)
                        Image(systemName: item.iconName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isEquipped ? neonCyan : .white.opacity(0.2))
                            .padding(4)
                            .background(isEquipped ? neonCyan.opacity(0.18) : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isEquipped ? neonCyan.opacity(0.6) : .clear, lineWidth: 1)
                            )
                    }
                }

                // 當日已審查旅客人數與單日配額進度
                Text("執勤配額 \(viewModel.inspectedCountInDay)/\(viewModel.quotaPerDay)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                // Day 天數指標
                HStack(spacing: 4) {
                    Text("DAY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.day)")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonCyan)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonCyan.opacity(0.35), lineWidth: 1)
                )

                // Score 總積分指標
                HStack(spacing: 4) {
                    Text("SCORE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%04d", viewModel.score))
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonAmber)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonAmber.opacity(0.35), lineWidth: 1)
                )

                // 可用星際幣（฿）餘額指標
                HStack(spacing: 3) {
                    Text("฿")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonGreen)
                    Text("\(viewModel.credits)")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonGreen.opacity(0.35), lineWidth: 1)
                )

                // 3 顆失誤警告紅燈（亮起代表已發生的失誤次數）
                HStack(spacing: 5) {
                    ForEach(0..<viewModel.maxStrikes, id: \.self) { index in
                        let isTriggered = index < viewModel.strikes
                        Circle()
                            .fill(isTriggered ? neonRed : Color.white.opacity(0.12))
                            .frame(width: 11, height: 11)
                            .overlay(
                                Circle()
                                    .stroke(isTriggered ? neonRed : Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: isTriggered ? neonRed.opacity(0.9) : .clear, radius: 5)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.strikes > 0 ? neonRed.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                )

                Spacer(minLength: 0)

                // 醒目的「📖 查閱星際法規手冊（Rulebook）」按鈕
                Button {
                    isShowingRulebook = true
                } label: {
                    HStack(spacing: 4) {
                        Text("📖 法規手冊")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [neonAmber, neonAmber.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: neonAmber.opacity(0.4), radius: 5)
                }
                .buttonStyle(.plain)
            }

            // 廉潔聲望與星際廉政署稽查風險緊湊狀態膠囊列
            HStack(spacing: 8) {
                // ⭐ 聲望膠囊（未滿 30 為霓虹青色，達 30 以上轉為琥珀金色）
                let repAccent = viewModel.reputation >= 30 ? neonAmber : neonCyan
                HStack(spacing: 4) {
                    Text("⭐ 聲望")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(repAccent)
                    Text("\(viewModel.reputation)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(repAccent.opacity(0.14))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(repAccent.opacity(0.5), lineWidth: 1)
                )

                // 👁️ 稽查風險膠囊（0% 灰綠色、1%~49% 琥珀色、50% 以上閃爍亮紅色警告）
                let risk = viewModel.auditRisk
                let isHighRisk = risk >= 50
                let riskColor: Color = risk == 0
                    ? neonGreen.opacity(0.75)
                    : (risk < 50 ? neonAmber : neonRed)

                HStack(spacing: 4) {
                    Text("👁️ 稽查風險")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(riskColor)
                    Text("\(risk)%")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(riskColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    riskColor.opacity(
                        isHighRisk
                            ? (isAuditWarningBlinking ? 0.32 : 0.10)
                            : 0.14
                    )
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            riskColor.opacity(isHighRisk ? (isAuditWarningBlinking ? 1.0 : 0.35) : 0.5),
                            lineWidth: isHighRisk ? 1.4 : 1
                        )
                )
                .shadow(
                    color: isHighRisk && isAuditWarningBlinking ? neonRed.opacity(0.65) : .clear,
                    radius: 5
                )

                Spacer()

                // 當聲望達到廉潔津貼門檻時，於右側顯示每日津貼預告標籤
                if viewModel.reputation >= 30 {
                    Text(viewModel.reputation >= 60 ? "廉潔津貼 +100" : "廉潔津貼 +50")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(neonAmber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(neonAmber.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 2. 今日速報橫幅
    /// 摘要顯示當日星曆年份、體溫/輻射上限、關卡階段提示，以及四大動態緊急指令（封鎖星系、禁運物、暫停目的、防疫狀態）
    private var dailyDirectiveBanner: some View {
        let reg = viewModel.currentRegulation
        let originsText = reg.bannedOrigins.isEmpty
            ? "無封鎖"
            : reg.bannedOrigins.map(\.shortName).sorted().joined(separator: "、")
        let itemsText = reg.bannedItems.isEmpty
            ? "無臨時禁運"
            : reg.bannedItems.map(\.shortName).sorted().joined(separator: "、")
        let purposeText = reg.restrictedPurpose?.shortName ?? "全數開放"
        let vaccineText = reg.requireVaccine ? "強制疫苗 (有機體)" : "常規免驗"

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("今日邊境緊急指令速報 // DAILY BRIEFING", systemImage: "bolt.horizontal.circle.fill")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(neonAmber)

                Spacer()

                Text("星曆 \(reg.currentYear) 年｜上限 \(String(format: "%.1f°C", reg.maxAllowedTemp)) / \(Int(reg.maxAllowedRadiation)) mSv")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(neonCyan)
            }

            // 當前天數解鎖的審查重點說明
            Text(viewModel.currentDayStageDescription)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))

            // 四宮格呈現當日四大動態管制指標
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                directiveMiniCell(
                    title: "封鎖星系",
                    value: originsText,
                    icon: "globe.Badge.chevron.backward",
                    highlight: !reg.bannedOrigins.isEmpty,
                    color: neonRed
                )

                directiveMiniCell(
                    title: "臨時禁運物",
                    value: itemsText,
                    icon: "shippingbox.and.arrow.backward.fill",
                    highlight: !reg.bannedItems.isEmpty,
                    color: neonAmber
                )

                directiveMiniCell(
                    title: "暫停入境目的",
                    value: purposeText,
                    icon: "hand.raised.fill",
                    highlight: reg.restrictedPurpose != nil,
                    color: neonPurple
                )

                directiveMiniCell(
                    title: "星際防疫狀態",
                    value: vaccineText,
                    icon: "cross.vial.fill",
                    highlight: reg.requireVaccine,
                    color: neonGreen
                )
            }
        }
        .padding(10)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(neonAmber.opacity(0.45), lineWidth: 1.2)
        )
    }

    /// 建立今日速報橫幅中的單一指令資訊小格
    private func directiveMiniCell(
        title: String,
        value: String,
        icon: String,
        highlight: Bool,
        color: Color
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(highlight ? color : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(highlight ? color : .white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(highlight ? color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 3. 中央電子護照終端機（雙欄網格完整呈現旅客所有數據）
    /// 顯示受檢旅客的頭像、姓名、有機分類標籤、硬體掃描異常提示與 12 項關鍵審查數據網格
    private var travelerPassportTerminal: some View {
        let traveler = viewModel.currentTraveler
        let reg = viewModel.currentRegulation
        // 呼叫規則引擎取得各項升級掃描儀的即時偵測結果
        let alerts = CustomsRuleEngine.scanAlerts(for: traveler, regulation: reg)

        // 檢查玩家已安裝哪些永久輔助掃描模組
        let hasBioScanner = viewModel.purchasedUpgrades.contains(.bioScanner)
        let hasForgeryDetector = viewModel.purchasedUpgrades.contains(.forgeryDetector)
        let hasExpiryChecker = viewModel.purchasedUpgrades.contains(.expiryChecker)
        let hasContrabandRadar = viewModel.purchasedUpgrades.contains(.contrabandRadar)

        // 唯有「已安裝該模組」且「該指標確實違規異常」時，才會在電子護照對應欄位亮起警示燈號
        let showTempAlert = hasBioScanner && alerts.isTempAbnormal
        let showRadAlert = hasBioScanner && alerts.isRadiationAbnormal
        let showForgeryAlert = hasForgeryDetector && alerts.isForgeryDetected
        let showExpiryAlert = hasExpiryChecker && alerts.isExpired
        let showOriginRadarAlert = hasContrabandRadar && alerts.isOriginBanned
        let showItemRadarAlert = hasContrabandRadar && alerts.isItemBannedOrContraband

        return VStack(alignment: .leading, spacing: 10) {
            // 終端標題列與有機體/非有機體分類標籤
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundStyle(neonCyan)
                    Text("旅客電子護照與生物掃描終端 // E-PASSPORT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(neonCyan)
                }
                Spacer()
                Text(traveler.species.organicLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background((traveler.species.isOrganic ? neonGreen : neonPurple).opacity(0.18))
                    .foregroundStyle(traveler.species.isOrganic ? neonGreen : neonPurple)
                    .clipShape(Capsule())
            }

            // 若已安裝「偽造編號與邏輯掃描儀」且偵測到第二層邏輯矛盾，於護照頂部跳出琥珀色警示條
            if showForgeryAlert, let hint = alerts.forgeryHint {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                    Text("⚠️ 偵測到邏輯矛盾：\(hint)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.black)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(neonAmber)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: neonAmber.opacity(0.5), radius: 5)
            }

            // 旅客物種全息頭像與姓名、編號摘要橫幅
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(neonCyan.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(neonCyan.opacity(0.5), lineWidth: 1.2)
                        )

                    Image(systemName: traveler.species.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(neonCyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(traveler.name)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text(traveler.serialCode)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(neonCyan.opacity(0.18))
                            .foregroundStyle(neonCyan)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text("\(traveler.species.displayName) · 來自\(traveler.origin.shortName)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }

            Divider()
                .overlay(neonCyan.opacity(0.25))

            // 雙欄網格：整齊呈現所有 12 項關鍵審查數據
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                // 01. 證件編號（克隆人必須以 CLN- 開頭）
                passportGridCell(
                    index: "01",
                    label: "證件編號 (SERIAL)",
                    value: traveler.serialCode,
                    icon: "barcode.viewfinder",
                    valueColor: .white
                )

                // 02. 旅客種族與有機分類
                passportGridCell(
                    index: "02",
                    label: "物種分類 (SPECIES)",
                    value: "\(traveler.species.shortName) (\(traveler.species.organicLabel))",
                    icon: traveler.species.symbolName,
                    valueColor: neonCyan
                )

                // 03. 來源星系（搭配違禁品與禁區雷達可自動標示封鎖區）
                passportGridCell(
                    index: "03",
                    label: "來源星系 (ORIGIN)",
                    value: traveler.origin.shortName,
                    icon: "location.north.line.fill",
                    valueColor: showOriginRadarAlert ? neonRed : .white,
                    badgeText: showOriginRadarAlert ? "封鎖區" : nil,
                    badgeColor: neonRed,
                    isAlertBackground: showOriginRadarAlert,
                    isGlowingRedBorder: showOriginRadarAlert
                )

                // 04. 入境目的
                passportGridCell(
                    index: "04",
                    label: "入境目的 (PURPOSE)",
                    value: traveler.purpose.shortName,
                    icon: traveler.purpose.symbolName,
                    valueColor: .white
                )

                // 05. 護照到期年份（搭配護照效期核對模組可反紅標示 EXPIRED）
                passportGridCell(
                    index: "05",
                    label: "護照效期 (EXPIRY)",
                    value: "星曆 \(traveler.passportExpiryYear) 年",
                    icon: "calendar.badge.clock",
                    valueColor: showExpiryAlert
                        ? neonRed
                        : (traveler.passportExpiryYear < reg.currentYear ? neonAmber : .white),
                    badgeText: showExpiryAlert ? "EXPIRED" : nil,
                    badgeColor: neonRed,
                    isAlertBackground: showExpiryAlert,
                    isGlowingRedBorder: showExpiryAlert
                )

                // 06. 入境許可證持有狀態
                passportGridCell(
                    index: "06",
                    label: "入境簽證 (PERMIT)",
                    value: traveler.hasEntryPermit ? "已核發 (VALID)" : "未持有 (NONE)",
                    icon: traveler.hasEntryPermit ? "checkmark.seal.fill" : "xmark.seal.fill",
                    valueColor: traveler.hasEntryPermit ? neonGreen : neonAmber
                )

                // 07. 外交豁免令持有狀態
                passportGridCell(
                    index: "07",
                    label: "外交豁免 (IMMUNITY)",
                    value: traveler.hasDiplomaticImmunity ? "持有 (ACTIVE)" : "無 (NONE)",
                    icon: "crown.fill",
                    valueColor: traveler.hasDiplomaticImmunity ? neonCyan : .white.opacity(0.7)
                )

                // 08. 星際疫苗接種證明
                passportGridCell(
                    index: "08",
                    label: "疫苗證明 (VACCINE)",
                    value: traveler.hasVaccineCert ? "已接種 (CERTIFIED)" : "未持有 (NONE)",
                    icon: "cross.vial.fill",
                    valueColor: traveler.hasVaccineCert ? neonGreen : neonAmber
                )

                // 09. 申報攜帶物品（搭配違禁品與禁區雷達可自動標示違禁/禁運品）
                passportGridCell(
                    index: "09",
                    label: "申報物品 (DECLARED)",
                    value: traveler.declaredItem.shortName,
                    icon: "cube.box.fill",
                    valueColor: showItemRadarAlert
                        ? neonRed
                        : (traveler.declaredItem == .none ? .white : neonAmber),
                    badgeText: showItemRadarAlert ? "違禁/禁運" : nil,
                    badgeColor: neonRed,
                    isAlertBackground: showItemRadarAlert,
                    isGlowingRedBorder: showItemRadarAlert
                )

                // 10. 隨身行李重量（超過 25 kg 時以琥珀色提示注意空箱走私）
                passportGridCell(
                    index: "10",
                    label: "行李重量 (WEIGHT)",
                    value: String(format: "%.1f kg", traveler.baggageWeight),
                    icon: "scalemass.fill",
                    valueColor: traveler.baggageWeight > 25.0 ? neonAmber : .white
                )

                // 11. 紅外線生物體溫（氣態能量體顯示 N/A；搭配生理警報器可反紅標示超標）
                passportGridCell(
                    index: "11",
                    label: "紅外線體溫 (TEMP)",
                    value: traveler.species == .gasEntity
                        ? "N/A (氣態無體溫)"
                        : String(format: "%.1f °C", traveler.bodyTemperature),
                    icon: "thermometer.high",
                    valueColor: showTempAlert
                        ? neonRed
                        : ((traveler.species != .gasEntity && traveler.bodyTemperature > reg.maxAllowedTemp)
                            ? neonAmber
                            : neonGreen),
                    badgeText: showTempAlert ? "⚠️ 數值超標" : nil,
                    badgeColor: neonRed,
                    isAlertBackground: showTempAlert,
                    isGlowingRedBorder: showTempAlert
                )

                // 12. 高能輻射感測劑量（搭配生理警報器可反紅標示超標）
                passportGridCell(
                    index: "12",
                    label: "輻射感測 (RADIATION)",
                    value: String(format: "%.1f mSv", traveler.radiationLevel),
                    icon: "aqi.high",
                    valueColor: showRadAlert
                        ? neonRed
                        : (traveler.radiationLevel > reg.maxAllowedRadiation ? neonAmber : neonGreen),
                    badgeText: showRadAlert ? "⚠️ 數值超標" : nil,
                    badgeColor: neonRed,
                    isAlertBackground: showRadAlert,
                    isGlowingRedBorder: showRadAlert
                )
            }
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(neonCyan.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: neonCyan.opacity(0.1), radius: 8)
    }

    // MARK: - 3.5 加密行賄對話面板
    /// 當違規旅客試圖行賄時顯示的私密通訊面板，提供「嚴正檢舉」與「私下收賄」兩項抉擇按鈕
    private func encryptedBribePanel(offer: BribeOffer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                        .foregroundStyle(neonAmber)
                    Text("⚠️ 收到私密通訊（行賄提案） // ENCRYPTED CHANNEL")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonAmber)
                }

                Spacer()

                // 顯示賄款金額與收賄將增加的稽查風險百分比
                HStack(spacing: 6) {
                    Text("+\(offer.amount) ฿")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(neonAmber.opacity(0.2))
                        .foregroundStyle(neonAmber)
                        .clipShape(Capsule())

                    Text("風險 +\(offer.riskIncrease)%")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(neonRed.opacity(0.22))
                        .foregroundStyle(neonRed)
                        .clipShape(Capsule())
                }
            }

            // 旅客私下行賄台詞
            Text(offer.dialogue)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.95))
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 10) {
                // 1. 「🛡️ 嚴正檢舉（+聲望 / 降風險）」按鈕（呼叫 reportBribe()）
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.reportBribe()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("🛡️ 嚴正檢舉（+聲望 / 降風險）")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background(
                        LinearGradient(
                            colors: [neonPurple.opacity(0.85), neonCyan.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(neonPurple, lineWidth: 1.3)
                    )
                    .shadow(color: neonPurple.opacity(0.35), radius: 4)
                }
                .buttonStyle(.plain)

                // 2. 「💰 私下收賄（+\(offer.amount) ฿）」按鈕（呼叫 acceptBribe()）
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.acceptBribe()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("💰 私下收賄（+\(offer.amount) ฿）")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background(
                        LinearGradient(
                            colors: [neonAmber, darkGoldWarning.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(neonAmber, lineWidth: 1.3)
                    )
                    .shadow(color: darkGoldWarning.opacity(0.35), radius: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.11, blue: 0.04), cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    neonAmber.opacity(0.85),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
        )
        .shadow(color: neonAmber.opacity(0.18), radius: 6)
    }

    /// 建立電子護照網格中的單一資料欄位卡片（支援升級模組異常紅框與徽章高亮）
    private func passportGridCell(
        index: String,
        label: String,
        value: String,
        icon: String,
        valueColor: Color,
        badgeText: String? = nil,
        badgeColor: Color = .red,
        isAlertBackground: Bool = false,
        isGlowingRedBorder: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(index)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(isGlowingRedBorder ? neonRed : neonCyan.opacity(0.8))
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isGlowingRedBorder ? neonRed.opacity(0.9) : .secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(badgeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(valueColor)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            isAlertBackground
                ? neonRed.opacity(0.22)
                : Color.black.opacity(0.36)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isGlowingRedBorder ? neonRed : Color.white.opacity(0.08),
                    lineWidth: isGlowingRedBorder ? 1.5 : 1
                )
        )
        .shadow(color: isGlowingRedBorder ? neonRed.opacity(0.55) : .clear, radius: 4)
    }

    // MARK: - 4. 底部判決區
    /// 顯示上一位旅客審查結果的法規回饋面板，以及「拒簽（DENY）」與「核准（APPROVE）」兩顆主操作按鈕
    private var bottomVerdictSection: some View {
        VStack(spacing: 8) {
            // 上一題詳細對錯原因與觸發法規層級回饋橫幅
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: feedbackIconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(feedbackAccentColor)
                    .padding(.top, 2)

                Text(viewModel.feedbackMessage)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(viewModel.isLastActionBribe ? neonAmber : .white)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(
                viewModel.isLastActionBribe
                    ? neonAmber.opacity(0.14)
                    : cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(feedbackAccentColor.opacity(0.65), lineWidth: 1.2)
            )

            // 「拒簽（DENY）」與「核准（APPROVE）」主裁決按鈕
            HStack(spacing: 12) {
                // 拒簽按鈕
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.processDecision(playerApproved: false)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.slash.fill")
                            .font(.system(size: 17, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("拒簽 (DENY)")
                                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                            Text("REJECT ENTRY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .opacity(0.85)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [neonRed.opacity(0.88), neonRed.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(neonRed, lineWidth: 1.5)
                    )
                    .shadow(color: neonRed.opacity(0.35), radius: 5)
                }
                .buttonStyle(.plain)

                // 核准按鈕
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.processDecision(playerApproved: true)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 17, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("核准 (APPROVE)")
                                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                            Text("GRANT ENTRY")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .opacity(0.85)
                        }
                    }
                    .foregroundStyle(Color.black.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [neonGreen, neonGreen.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(neonGreen, lineWidth: 1.5)
                    )
                    .shadow(color: neonGreen.opacity(0.35), radius: 5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 根據上一次裁決結果（正確、失誤、收賄或初始狀態）決定回饋面板的主題色
    private var feedbackAccentColor: Color {
        if viewModel.isLastActionBribe {
            return neonAmber
        }
        guard let isCorrect = viewModel.lastDecisionCorrect else {
            return neonCyan
        }
        return isCorrect ? neonGreen : neonRed
    }

    /// 根據上一次裁決結果決定回饋面板左側的 SF Symbols 圖示
    private var feedbackIconName: String {
        if viewModel.isLastActionBribe {
            return "exclamationmark.shield.fill"
        }
        guard let isCorrect = viewModel.lastDecisionCorrect else {
            return "terminal.fill"
        }
        return isCorrect ? "checkmark.circle.fill" : "exclamationmark.octagon.fill"
    }

    // MARK: - 5. Game Over 結算畫面
    /// 當玩家因累積 3 次失誤或貪污遭廉政署逮捕時顯示的全螢幕結算遮罩
    private var gameOverOverlay: some View {
        let isCorruption = viewModel.gameOverReason == .firedForCorruption
        let titleText = isCorruption
            ? "🚨 星際廉政署逮捕令：因貪污受賄遭到撤職"
            : "審查失職：終止合約"
        let descriptionText = isCorruption
            ? "星際廉政署（INTERNAL AFFAIRS）已查獲您私下收取違規旅客賄賂並偽造放行紀錄的鐵證，即刻撤銷職位並移送星際法庭。"
            : "您已累積 3 次重大海關審查失誤，深度邊境安全總署已終止您的聘僱合約並撤銷審查權限。"

        return ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: isCorruption ? "lock.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(neonRed)
                    .shadow(color: neonRed.opacity(0.8), radius: 10)

                Text(titleText)
                    .font(.system(size: 17, weight: .heavy, design: .monospaced))
                    .foregroundStyle(neonRed)
                    .multilineTextAlignment(.center)

                Text(descriptionText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                // 顯示最後一題導致遊戲結束的詳細回饋紀錄
                Text(viewModel.feedbackMessage)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(neonAmber)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // 最終統計數據（執勤天數、最終積分、廉潔聲望）
                HStack(spacing: 22) {
                    VStack(spacing: 4) {
                        Text("執勤天數")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("DAY \(viewModel.day)")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundStyle(neonCyan)
                    }

                    VStack(spacing: 4) {
                        Text("最終積分")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.score)")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundStyle(neonAmber)
                    }

                    VStack(spacing: 4) {
                        Text("廉潔聲望")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.reputation)")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundStyle(neonGreen)
                    }
                }
                .padding(.vertical, 4)

                // 重新開始新局按鈕
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.restartGame()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("重新執勤 (RESTART SHIFT)")
                            .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(neonCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: neonCyan.opacity(0.5), radius: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(neonRed.opacity(0.85), lineWidth: 2)
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - 星際法規手冊彈出視窗（Rulebook Sheet）
/// 供玩家隨時查閱「六層優先級漏斗法規」與「今日動態公告 & 8 大物種有機分類表」的獨立視窗
struct RulebookSheetView: View {
    /// 當日生效的動態海關法規
    let regulation: DailyRegulation
    /// 當前執勤天數
    let day: Int

    /// 用於關閉彈出視窗的環境變數
    @Environment(\.dismiss) private var dismiss
    /// 當前選中的分頁索引（0 為六層優先級法規，1 為今日動態公告與物種對照表）
    @State private var selectedTab: Int = 0

    // 法規手冊專屬配色定義
    private let sheetBackground = Color(red: 0.04, green: 0.06, blue: 0.11)
    private let cardBackground = Color(red: 0.08, green: 0.12, blue: 0.19)
    private let neonCyan = Color(red: 0.00, green: 0.90, blue: 0.96)
    private let neonAmber = Color(red: 1.00, green: 0.73, blue: 0.16)
    private let neonRed = Color(red: 1.00, green: 0.27, blue: 0.36)
    private let neonGreen = Color(red: 0.15, green: 0.92, blue: 0.55)
    private let neonPurple = Color(red: 0.72, green: 0.45, blue: 1.00)

    var body: some View {
        NavigationStack {
            ZStack {
                sheetBackground.ignoresSafeArea()

                VStack(spacing: 12) {
                    // 頂部分頁切換器
                    Picker("法規手冊分頁", selection: $selectedTab) {
                        Text("六層優先級法規").tag(0)
                        Text("今日動態公告 & 物種表").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    ScrollView {
                        if selectedTab == 0 {
                            sixLayerRulesContent
                        } else {
                            dailyAndSpeciesContent
                        }
                    }
                }
            }
            .navigationTitle("📖 星際海關法規手冊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold).monospaced())
                    .foregroundStyle(neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: 分頁 1：常駐六層漏斗法規
    /// 完整列出由第一層至第六層的海關審查優先級規則與所有特殊豁免條款
    private var sixLayerRulesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("⚠️ 審查鐵則：請嚴格由【第一層】往【第六層】依序比對，高優先級直接決定結果！")
                .font(.body.weight(.bold).monospaced())
                .foregroundStyle(neonAmber)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(neonAmber.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            ruleLayerCard(
                badge: "PRIORITY 01",
                title: "第一層：絕對安全與雙軌生理紅線",
                subtitle: "最高優先級，連外交官與難民都不可豁免",
                accent: neonRed,
                rules: [
                    "1. 一級違禁品：攜帶「異星孢子」或「量子走私核心」➔ 絕對拒簽。",
                    "2. 氣態能量體：無體溫，僅檢定輻射。若輻射值 > \(Int(regulation.maxAllowedRadiation)) mSv ➔ 拒簽。",
                    "3. 非氣態生命體溫：若非「矽基生命」且體溫 > \(String(format: "%.1f°C", regulation.maxAllowedTemp)) ➔ 拒簽（矽基生命不限體溫）。",
                    "4. 非氣態生命輻射：上限為 \(Int(regulation.maxAllowedRadiation)) mSv；但「獵戶座重工區」居民享有 +25 mSv 寬容值（即上限 \(Int(regulation.maxAllowedRadiation + 25)) mSv），超標 ➔ 拒簽。"
                ]
            )

            ruleLayerCard(
                badge: "PRIORITY 02",
                title: "第二層：證件偽造與邏輯矛盾抓包",
                subtitle: "Day 2 解鎖｜比對欄位是否自相矛盾",
                accent: neonAmber,
                rules: [
                    "1. 偽造外交豁免令：持有外交豁免令，但種族不是「星際外交官」➔ 拒簽。",
                    "2. 非法克隆體：種族為「克隆人」，但證件編號不是以 \"CLN-\" 開頭 ➔ 拒簽。",
                    "3. 疑似空箱走私：申報物品為「無」，但行李重量 > 25.0 kg ➔ 拒簽。"
                ]
            )

            ruleLayerCard(
                badge: "PRIORITY 03",
                title: "第三層：特殊身分與人道豁免覆寫",
                subtitle: "Day 2 解鎖｜符合條件可直接核准或攔截",
                accent: neonCyan,
                rules: [
                    "1. 外交特權：種族為「星際外交官」且持有「外交豁免令」➔ 直接核准放行（無視第 4~6 層封鎖、禁運、簽證與護照過期）。",
                    "2. 難民庇護：入境目的為「難民庇護」且申報物品為「無」➔ 直接核准放行（無視封鎖、無簽證與過期護照）；若攜帶任何物品 ➔ 立即拒簽。"
                ]
            )

            ruleLayerCard(
                badge: "PRIORITY 04",
                title: "第四層：每日動態緊急指令",
                subtitle: "Day 3 解鎖｜依據今日公告動態攔截",
                accent: neonPurple,
                rules: [
                    "1. 封鎖星系：來自今日公告封鎖之星系 ➔ 拒簽。",
                    "2. 暫停目的：入境目的為今日暫停受理之目的 ➔ 拒簽。",
                    "3. 星際防疫：今日啟動防疫時，所有「有機體」必須持有疫苗證明，否則 ➔ 拒簽（非有機體免驗）。"
                ]
            )

            ruleLayerCard(
                badge: "PRIORITY 05",
                title: "第五層：受控物品與種族/目的交叉檢定",
                subtitle: "Day 4 解鎖｜特殊物品限制與半機械人巢狀豁免",
                accent: neonAmber,
                rules: [
                    "1. 蟲后費洛蒙：僅限「蟲族工蜂」攜帶，其他種族攜帶 ➔ 拒簽。",
                    "2. 暗物質電池：僅限「科學研究」目的攜帶，其他目的攜帶 ➔ 拒簽。",
                    "3. 今日臨時禁運物：攜帶今日禁運物品 ➔ 拒簽；【唯一例外】「半機械人」攜帶「液態金屬」屬維修自用可豁免，但仍須繼續通過第六層基礎文件檢查！"
                ]
            )

            ruleLayerCard(
                badge: "PRIORITY 06",
                title: "第六層：基礎文件與貿易協定核對",
                subtitle: "最後關卡｜護照效期與免簽協定",
                accent: neonGreen,
                rules: [
                    "1. 護照效期：護照到期年份 < \(regulation.currentYear) 年 ➔ 拒簽。",
                    "2. 入境簽證：未持有入境許可證者，僅「太陽系居民」或「天狼星貿易聯邦 + 商務貿易目的」可享免簽核准，其餘無證者 ➔ 拒簽。",
                    "3. 全部合規：通過上述所有檢定 ➔ 核准放行！"
                ]
            )
        }
        .padding(16)
    }

    // MARK: 分頁 2：今日動態公告與物種有機對照表
    /// 顯示當日生效的動態海關法規完整列表，以及 8 大物種是否屬於有機生命體的對照表
    private var dailyAndSpeciesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 今日動態公告詳情卡片
            VStack(alignment: .leading, spacing: 10) {
                Text("📡 今日動態海關公告 (DAY \(day))")
                    .font(.title3.weight(.heavy).monospaced())
                    .foregroundStyle(neonAmber)

                Divider().overlay(neonAmber.opacity(0.3))

                bulletRow(label: "當前星曆年份", value: "\(regulation.currentYear) 年（護照到期年須 ≥ \(regulation.currentYear)）")
                bulletRow(label: "標準體溫上限", value: String(format: "%.1f °C（矽基生命不限、氣態無體溫）", regulation.maxAllowedTemp))
                bulletRow(label: "標準輻射上限", value: String(format: "%.1f mSv（獵戶座重工區放寬為 %.1f mSv）", regulation.maxAllowedRadiation, regulation.maxAllowedRadiation + 25.0))
                bulletRow(
                    label: "今日封鎖星系",
                    value: regulation.bannedOrigins.isEmpty
                        ? "無封鎖星系"
                        : regulation.bannedOrigins.map(\.displayName).sorted().joined(separator: "、")
                )
                bulletRow(
                    label: "今日臨時禁運",
                    value: regulation.bannedItems.isEmpty
                        ? "無臨時禁運物品"
                        : regulation.bannedItems.map(\.displayName).sorted().joined(separator: "、")
                )
                bulletRow(
                    label: "暫停入境目的",
                    value: regulation.restrictedPurpose?.displayName ?? "無（全數開放）"
                )
                bulletRow(
                    label: "星際防疫要求",
                    value: regulation.requireVaccine ? "已啟動（所有有機體必須持有疫苗證明）" : "未啟動（免驗疫苗證明）"
                )
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonAmber.opacity(0.45), lineWidth: 1.2)
            )

            // 8 大物種有機/非有機與特性一覽表卡片
            VStack(alignment: .leading, spacing: 10) {
                Text("🧬 星際物種生理分類與特殊規則")
                    .font(.title3.weight(.heavy).monospaced())
                    .foregroundStyle(neonCyan)

                Divider().overlay(neonCyan.opacity(0.3))

                ForEach(Species.allCases) { species in
                    HStack(spacing: 10) {
                        Image(systemName: species.symbolName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(neonCyan)
                            .frame(width: 26)

                        Text(species.displayName)
                            .font(.body.weight(.bold).monospaced())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Spacer()

                        Text(species.organicLabel)
                            .font(.subheadline.weight(.bold).monospaced())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((species.isOrganic ? neonGreen : neonPurple).opacity(0.22))
                            .foregroundStyle(species.isOrganic ? neonGreen : neonPurple)
                            .clipShape(Capsule())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonCyan.opacity(0.45), lineWidth: 1.2)
            )
        }
        .padding(16)
    }

    /// 建立單一法規層級說明卡片
    private func ruleLayerCard(
        badge: String,
        title: String,
        subtitle: String,
        accent: Color,
        rules: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(badge)
                    .font(.footnote.weight(.heavy).monospaced())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.2))
                    .foregroundStyle(accent)
                    .clipShape(Capsule())

                Spacer()

                Text(subtitle)
                    .font(.footnote.weight(.semibold).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(title)
                .font(.title3.weight(.heavy).monospaced())
                .foregroundStyle(accent)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(accent.opacity(0.3))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(rules, id: \.self) { rule in
                    Text(rule)
                        .font(.body.weight(.medium).monospaced())
                        .foregroundStyle(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.45), lineWidth: 1.2)
        )
    }

    /// 建立今日動態公告中的單列項目文字
    private func bulletRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("▪ \(label)：")
                .font(.body.weight(.bold).monospaced())
                .foregroundStyle(neonCyan)
            Text(value)
                .font(.body.weight(.medium).monospaced())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ContentView()
}
