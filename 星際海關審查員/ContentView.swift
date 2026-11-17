import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var isShowingRulebook = false

    // 科幻終端機配色定義
    private let terminalBackground = Color(red: 0.03, green: 0.05, blue: 0.09)
    private let cardBackground = Color(red: 0.07, green: 0.11, blue: 0.17)
    private let neonCyan = Color(red: 0.00, green: 0.90, blue: 0.96)
    private let neonAmber = Color(red: 1.00, green: 0.73, blue: 0.16)
    private let neonRed = Color(red: 1.00, green: 0.27, blue: 0.36)
    private let neonGreen = Color(red: 0.15, green: 0.92, blue: 0.55)
    private let neonPurple = Color(red: 0.72, green: 0.45, blue: 1.00)

    var body: some View {
        ZStack {
            terminalBackground
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // 1. 頂部狀態列（Day、Score、3 顆失誤紅燈、法規手冊按鈕）
                topStatusBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 2. 今日速報橫幅（封鎖星系、禁運物品、暫停目的、防疫狀態）
                        dailyDirectiveBanner

                        // 3. 中央電子護照終端機（雙欄網格呈現完整旅客數據）
                        travelerPassportTerminal
                    }
                    .padding(.vertical, 2)
                }

                // 4. 底部判決區（上一題對錯原因 + 觸發層級 + 拒簽/核准按鈕）
                bottomVerdictSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // 5. Game Over 結算遮罩
            if viewModel.isGameOver {
                gameOverOverlay
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingRulebook) {
            RulebookSheetView(
                regulation: viewModel.currentRegulation,
                day: viewModel.day
            )
        }
    }

    // MARK: - 1. 頂部狀態列
    private var topStatusBar: some View {
        VStack(spacing: 8) {
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
                Text("執勤配額 \(viewModel.inspectedCountInDay)/\(viewModel.quotaPerDay)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                // Day 指標
                HStack(spacing: 4) {
                    Text("DAY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.day)")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonCyan.opacity(0.35), lineWidth: 1)
                )

                // Score 指標
                HStack(spacing: 4) {
                    Text("SCORE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%04d", viewModel.score))
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(neonAmber)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonAmber.opacity(0.35), lineWidth: 1)
                )

                // 3 顆失誤紅燈
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.maxStrikes, id: \.self) { index in
                        let isTriggered = index < viewModel.strikes
                        Circle()
                            .fill(isTriggered ? neonRed : Color.white.opacity(0.12))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(isTriggered ? neonRed : Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: isTriggered ? neonRed.opacity(0.9) : .clear, radius: 5)
                    }
                }
                .padding(.horizontal, 10)
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
                    HStack(spacing: 5) {
                        Text("📖 法規手冊")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        Text("RULEBOOK")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
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
        }
    }

    // MARK: - 2. 今日速報橫幅
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

            Text(viewModel.currentDayStageDescription)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))

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
    private var travelerPassportTerminal: some View {
        let traveler = viewModel.currentTraveler
        let reg = viewModel.currentRegulation

        return VStack(alignment: .leading, spacing: 10) {
            // 終端標題列
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

            // 旅客頭像與姓名橫幅
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

            // 雙欄網格：整齊呈現所有 12 項關鍵審查數據（含要求的全部 10+ 項欄位）
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                // 1. 證件編號
                passportGridCell(
                    index: "01",
                    label: "證件編號 (SERIAL)",
                    value: traveler.serialCode,
                    icon: "barcode.viewfinder",
                    valueColor: .white
                )

                // 2. 旅客種族
                passportGridCell(
                    index: "02",
                    label: "物種分類 (SPECIES)",
                    value: "\(traveler.species.shortName) (\(traveler.species.organicLabel))",
                    icon: traveler.species.symbolName,
                    valueColor: neonCyan
                )

                // 3. 來源星系
                passportGridCell(
                    index: "03",
                    label: "來源星系 (ORIGIN)",
                    value: traveler.origin.shortName,
                    icon: "location.north.line.fill",
                    valueColor: .white
                )

                // 4. 入境目的
                passportGridCell(
                    index: "04",
                    label: "入境目的 (PURPOSE)",
                    value: traveler.purpose.shortName,
                    icon: traveler.purpose.symbolName,
                    valueColor: .white
                )

                // 5. 護照到期年份
                passportGridCell(
                    index: "05",
                    label: "護照效期 (EXPIRY)",
                    value: "星曆 \(traveler.passportExpiryYear) 年",
                    icon: "calendar.badge.clock",
                    valueColor: traveler.passportExpiryYear < reg.currentYear ? neonAmber : .white
                )

                // 6. 入境許可證
                passportGridCell(
                    index: "06",
                    label: "入境簽證 (PERMIT)",
                    value: traveler.hasEntryPermit ? "已核發 (VALID)" : "未持有 (NONE)",
                    icon: traveler.hasEntryPermit ? "checkmark.seal.fill" : "xmark.seal.fill",
                    valueColor: traveler.hasEntryPermit ? neonGreen : neonAmber
                )

                // 7. 外交豁免令
                passportGridCell(
                    index: "07",
                    label: "外交豁免 (IMMUNITY)",
                    value: traveler.hasDiplomaticImmunity ? "持有 (ACTIVE)" : "無 (NONE)",
                    icon: "crown.fill",
                    valueColor: traveler.hasDiplomaticImmunity ? neonCyan : .white.opacity(0.7)
                )

                // 8. 疫苗證明
                passportGridCell(
                    index: "08",
                    label: "疫苗證明 (VACCINE)",
                    value: traveler.hasVaccineCert ? "已接種 (CERTIFIED)" : "未持有 (NONE)",
                    icon: "cross.vial.fill",
                    valueColor: traveler.hasVaccineCert ? neonGreen : neonAmber
                )

                // 9. 申報物品
                passportGridCell(
                    index: "09",
                    label: "申報物品 (DECLARED)",
                    value: traveler.declaredItem.shortName,
                    icon: "cube.box.fill",
                    valueColor: traveler.declaredItem == .none ? .white : neonAmber
                )

                // 10. 行李重量
                passportGridCell(
                    index: "10",
                    label: "行李重量 (WEIGHT)",
                    value: String(format: "%.1f kg", traveler.baggageWeight),
                    icon: "scalemass.fill",
                    valueColor: traveler.baggageWeight > 25.0 ? neonAmber : .white
                )

                // 11. 生物體溫
                passportGridCell(
                    index: "11",
                    label: "紅外線體溫 (TEMP)",
                    value: traveler.species == .gasEntity
                        ? "N/A (氣態無體溫)"
                        : String(format: "%.1f °C", traveler.bodyTemperature),
                    icon: "thermometer.high",
                    valueColor: (traveler.species != .gasEntity && traveler.bodyTemperature > reg.maxAllowedTemp)
                        ? neonAmber
                        : neonGreen
                )

                // 12. 輻射劑量
                passportGridCell(
                    index: "12",
                    label: "輻射感測 (RADIATION)",
                    value: String(format: "%.1f mSv", traveler.radiationLevel),
                    icon: "aqi.high",
                    valueColor: traveler.radiationLevel > reg.maxAllowedRadiation ? neonAmber : neonGreen
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

    private func passportGridCell(
        index: String,
        label: String,
        value: String,
        icon: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(index)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(neonCyan.opacity(0.8))
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
        .background(Color.black.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 4. 底部判決區
    private var bottomVerdictSection: some View {
        VStack(spacing: 8) {
            // 上一題詳細對錯原因與觸發法規層級
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: feedbackIconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(feedbackAccentColor)
                    .padding(.top, 2)

                Text(viewModel.feedbackMessage)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(feedbackAccentColor.opacity(0.65), lineWidth: 1.2)
            )

            // 「拒簽（DENY）」與「核准（APPROVE）」按鈕
            HStack(spacing: 12) {
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

    private var feedbackAccentColor: Color {
        guard let isCorrect = viewModel.lastDecisionCorrect else {
            return neonCyan
        }
        return isCorrect ? neonGreen : neonRed
    }

    private var feedbackIconName: String {
        guard let isCorrect = viewModel.lastDecisionCorrect else {
            return "terminal.fill"
        }
        return isCorrect ? "checkmark.circle.fill" : "exclamationmark.octagon.fill"
    }

    // MARK: - 5. Game Over 結算畫面
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(neonRed)
                    .shadow(color: neonRed.opacity(0.8), radius: 10)

                Text("審查官停職處分 // TERMINATED")
                    .font(.system(size: 19, weight: .heavy, design: .monospaced))
                    .foregroundStyle(neonRed)

                Text("您已累積 3 次重大海關審查失誤，深度邊境安全總署已撤銷您的審查權限。")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text(viewModel.feedbackMessage)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(neonAmber)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 28) {
                    VStack(spacing: 4) {
                        Text("執勤天數")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("DAY \(viewModel.day)")
                            .font(.system(size: 20, weight: .heavy, design: .monospaced))
                            .foregroundStyle(neonCyan)
                    }

                    VStack(spacing: 4) {
                        Text("最終積分")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.score)")
                            .font(.system(size: 20, weight: .heavy, design: .monospaced))
                            .foregroundStyle(neonAmber)
                    }
                }
                .padding(.vertical, 4)

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
struct RulebookSheetView: View {
    let regulation: DailyRegulation
    let day: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

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
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: 分頁 1：常駐六層漏斗法規
    private var sixLayerRulesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ 審查鐵則：請嚴格由【第一層】往【第六層】依序比對，高優先級直接決定結果！")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(neonAmber)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(neonAmber.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

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
    private var dailyAndSpeciesContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 今日動態公告詳情
            VStack(alignment: .leading, spacing: 8) {
                Text("📡 今日動態海關公告 (DAY \(day))")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
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
            .padding(14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonAmber.opacity(0.45), lineWidth: 1.2)
            )

            // 8 大物種有機/非有機與特性一覽表
            VStack(alignment: .leading, spacing: 8) {
                Text("🧬 星際物種生理分類與特殊規則")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(neonCyan)

                Divider().overlay(neonCyan.opacity(0.3))

                ForEach(Species.allCases) { species in
                    HStack(spacing: 10) {
                        Image(systemName: species.symbolName)
                            .foregroundStyle(neonCyan)
                            .frame(width: 22)

                        Text(species.displayName)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(species.organicLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((species.isOrganic ? neonGreen : neonPurple).opacity(0.2))
                            .foregroundStyle(species.isOrganic ? neonGreen : neonPurple)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonCyan.opacity(0.45), lineWidth: 1.2)
            )
        }
        .padding(16)
    }

    private func ruleLayerCard(
        badge: String,
        title: String,
        subtitle: String,
        accent: Color,
        rules: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(badge)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(accent.opacity(0.2))
                    .foregroundStyle(accent)
                    .clipShape(Capsule())

                Spacer()

                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                .foregroundStyle(accent)

            Divider().overlay(accent.opacity(0.3))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(rules, id: \.self) { rule in
                    Text(rule)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.45), lineWidth: 1.2)
        )
    }

    private func bulletRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("▪ \(label)：")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(neonCyan)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ContentView()
}
