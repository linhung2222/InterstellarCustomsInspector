import SwiftUI

/// 每日結算與裝備商店畫面（Daily Settlement & Upgrade Shop）
struct DailySummaryShopView: View {
    /// 綁定遊戲主狀態控制器，用於讀取結算報告與執行裝備購買
    @Bindable var viewModel: GameViewModel

    // MARK: - 科幻終端機配色定義
    /// 終端機底層深色背景
    private let terminalBackground = Color(red: 0.03, green: 0.05, blue: 0.09)
    /// 卡片區塊深藍灰背景
    private let cardBackground = Color(red: 0.07, green: 0.11, blue: 0.17)
    /// 霓虹青色（用於主要標題、已安裝標記與下一步主按鈕）
    private let neonCyan = Color(red: 0.00, green: 0.90, blue: 0.96)
    /// 霓虹琥珀金（用於星際幣金額、結算收據邊框與購買按鈕）
    private let neonAmber = Color(red: 1.00, green: 0.73, blue: 0.16)
    /// 霓虹警示紅（用於失誤紅燈、消耗品標籤與廉政署罰款橫幅）
    private let neonRed = Color(red: 1.00, green: 0.27, blue: 0.36)
    /// 霓虹翠綠色（用於全勤零失誤徽章與正常狀態）
    private let neonGreen = Color(red: 0.15, green: 0.92, blue: 0.55)

    /// 每日結算與升級商店主視圖結構
    var body: some View {
        ZStack {
            // 鋪滿全螢幕的深色科幻背景
            terminalBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // 頂部標題列（顯示天數與目前累積失誤紅燈）
                headerBar

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 16) {
                        // 上半部：第 X 天值勤結算報告卡片
                        settlementReportCard

                        // 下半部：海關終端機升級商店列表
                        upgradeShopSection
                    }
                    .padding(.vertical, 4)
                }

                // 底部主按鈕：結束採購並開始第 X+1 天值勤
                nextDayButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 頂部標題列
    /// 顯示當前結算天數標題與右上角即時失誤紅燈狀態
    private var headerBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.text.page.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(neonCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY SHIFT SETTLEMENT // DAY \(viewModel.day)")
                        .font(.footnote.weight(.bold).monospaced())
                        .foregroundStyle(neonCyan)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("第 \(viewModel.day) 天值勤結算與終端機升級商店")
                        .font(.title2.weight(.heavy).monospaced())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Spacer()

            // 目前失誤燈號狀態（購買「人事失誤紀錄抹除」時可即時看到紅燈消除動畫）
            HStack(spacing: 6) {
                Text("失誤")
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                ForEach(0..<viewModel.maxStrikes, id: \.self) { index in
                    let isTriggered = index < viewModel.strikes
                    Circle()
                        .fill(isTriggered ? neonRed : Color.white.opacity(0.15))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(isTriggered ? neonRed : Color.white.opacity(0.3), lineWidth: 1.2)
                        )
                        .shadow(color: isTriggered ? neonRed.opacity(0.8) : .clear, radius: 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(viewModel.strikes > 0 ? neonRed.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - 上半部：第 X 天值勤結算報告
    /// 顯示當日審查正確率、基礎收入、全勤獎金、廉潔津貼、廉政署抽查結果與目前可用星際幣餘額
    private var settlementReportCard: some View {
        // 若 latestReport 尚未產生則動態組裝預設報告（供 Preview 或備援顯示）
        let report = viewModel.latestReport ?? DailySummaryReport(
            correctCount: viewModel.dailyCorrectCount,
            mistakeCount: viewModel.dailyMistakeCount,
            baseReward: viewModel.dailyCorrectCount * 100,
            perfectShiftBonus: viewModel.dailyMistakeCount == 0 ? 150 : 0,
            reputationBonus: viewModel.reputation >= 60 ? 100 : (viewModel.reputation >= 30 ? 50 : 0),
            auditResult: .notTriggered,
            totalEarned: viewModel.dailyCorrectCount * 100 + (viewModel.dailyMistakeCount == 0 ? 150 : 0)
        )
        let isPerfect = report.mistakeCount == 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("第 \(viewModel.day) 天值勤結算報告 // SHIFT RECEIPT", systemImage: "doc.text.magnifyingglass")
                    .font(.title3.weight(.bold).monospaced())
                    .foregroundStyle(neonAmber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                // 若當日零失誤則顯示全勤徽章
                if isPerfect {
                    Text("PERFECT SHIFT")
                        .font(.footnote.weight(.heavy).monospaced())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(neonGreen.opacity(0.2))
                        .foregroundStyle(neonGreen)
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Divider()
                .overlay(neonAmber.opacity(0.35))

            // 結算收據明細列
            VStack(spacing: 10) {
                receiptRow(
                    title: "審查正確人數",
                    value: "\(report.correctCount) / \(viewModel.quotaPerDay) 人 (失誤 \(report.mistakeCount) 次)",
                    valueColor: .white
                )

                receiptRow(
                    title: "當日基礎收入",
                    value: "+\(report.baseReward) ฿",
                    valueColor: .white
                )

                receiptRow(
                    title: "全勤零失誤獎金",
                    value: isPerfect ? "+\(report.perfectShiftBonus) ฿ (達成全勤)" : "0 ฿ (未達成)",
                    valueColor: isPerfect ? neonGreen : .secondary
                )

                receiptRow(
                    title: "廉潔聲望津貼 (聲望 \(viewModel.reputation))",
                    value: report.reputationBonus > 0
                        ? "+\(report.reputationBonus) 分 / +\(report.reputationBonus) ฿"
                        : "0 ฿ (聲望滿 30 解鎖)",
                    valueColor: report.reputationBonus > 0 ? neonCyan : .secondary
                )

                // 星際廉政署抽查結果欄位（遭開罰時以紅底醒目標示）
                auditResultBanner(for: report.auditResult)

                Divider()
                    .overlay(Color.white.opacity(0.15))

                receiptRow(
                    title: "當日總獲得積分",
                    value: "+\(report.totalEarned) ฿",
                    valueColor: neonAmber,
                    isBold: true
                )
            }
            .padding(12)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // 醒目的「目前可用積分（CREDITS）」餘額橫幅
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("目前可用積分 (AVAILABLE CREDITS)")
                        .font(.subheadline.weight(.bold).monospaced())
                        .foregroundStyle(neonCyan.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("可用於採購下方海關終端機輔助掃描模組與紀錄抹除")
                        .font(.footnote.weight(.medium).monospaced())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("฿")
                        .font(.title2.weight(.heavy).monospaced())
                        .foregroundStyle(neonAmber)
                    Text("\(viewModel.credits)")
                        .font(.title.weight(.heavy).monospaced())
                        .foregroundStyle(neonAmber)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [neonAmber.opacity(0.16), neonCyan.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(neonAmber.opacity(0.6), lineWidth: 1.2)
            )
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(neonAmber.opacity(0.45), lineWidth: 1.5)
        )
    }

    /// 建立結算收據中的單列項目視圖
    private func receiptRow(
        title: String,
        value: String,
        valueColor: Color,
        isBold: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font((isBold ? Font.title3 : Font.body).weight(isBold ? .heavy : .medium).monospaced())
                .foregroundStyle(isBold ? .white : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            Text(value)
                .font((isBold ? Font.title3 : Font.body).weight(.heavy).monospaced())
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    /// 根據星際廉政署的每日抽查結果，渲染對應顏色的狀態列或警告橫幅
    @ViewBuilder
    private func auditResultBanner(for result: AuditResult) -> some View {
        switch result {
        case .notTriggered:
            // 無風險（0%），未啟動抽查
            HStack {
                Text("星際廉政署抽查結果")
                    .font(.body.weight(.medium).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text("今日無異常 (未啟動抽查)")
                    .font(.body.weight(.heavy).monospaced())
                    .foregroundStyle(neonGreen.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

        case .passed:
            // 有風險但未抽中違規帳目，驚險過關
            HStack {
                Text("星際廉政署抽查結果")
                    .font(.body.weight(.medium).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text("👁️ 抽查完畢：驚險過關 (目前風險 \(viewModel.auditRisk)%)")
                    .font(.body.weight(.heavy).monospaced())
                    .foregroundStyle(neonAmber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

        case .fined(let penalty):
            // 抽查中標！強制扣繳罰金並記 1 次重大失誤紅燈
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 3) {
                    Text("🚨 星際廉政署抽查結果：查獲帳目異常！")
                        .font(.body.weight(.heavy).monospaced())
                        .foregroundStyle(.white)
                    Text("強制扣繳罰金 -\(penalty) ฿、記 1 次重大失誤紅燈（風險降至 \(viewModel.auditRisk)%）")
                        .font(.callout.weight(.bold).monospaced())
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(neonRed.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(neonRed, lineWidth: 1.5)
            )

        case .arrested:
            // 高風險下遭查獲，即刻逮捕撤職
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("🚨 星際廉政署抽查結果：罪證確鑿，即刻逮捕撤職！")
                    .font(.body.weight(.heavy).monospaced())
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(neonRed)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - 下半部：海關終端機升級商店
    /// 列出所有可採購的終端機永久掃描模組與單次消耗品卡片
    private var upgradeShopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("海關終端機升級商店 // TERMINAL UPGRADE SHOP", systemImage: "cpu.fill")
                    .font(.title3.weight(.bold).monospaced())
                    .foregroundStyle(neonCyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Text("已安裝 \(viewModel.purchasedUpgrades.count)/4 模組")
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            VStack(spacing: 12) {
                ForEach(UpgradeItem.allCases) { item in
                    upgradeItemCard(for: item)
                }
            }
        }
    }

    /// 建立單一升級裝備或消耗品的商店商品卡片視圖
    private func upgradeItemCard(for item: UpgradeItem) -> some View {
        let isInstalled = !item.isConsumable && viewModel.purchasedUpgrades.contains(item)
        let canBuy = viewModel.canPurchase(item)

        return HStack(alignment: .center, spacing: 14) {
            // 左側裝備圖示框
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isInstalled
                            ? neonCyan.opacity(0.18)
                            : (item.isConsumable ? neonRed.opacity(0.15) : neonAmber.opacity(0.14))
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isInstalled
                                    ? neonCyan.opacity(0.6)
                                    : (item.isConsumable ? neonRed.opacity(0.45) : neonAmber.opacity(0.45)),
                                lineWidth: 1.2
                            )
                    )

                Image(systemName: item.iconName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        isInstalled
                            ? neonCyan
                            : (item.isConsumable ? neonRed : neonAmber)
                    )
            }

            // 中央名稱、類型標籤與功能說明
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.title3.weight(.heavy).monospaced())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(item.isConsumable ? "消耗品" : "永久")
                        .font(.footnote.weight(.bold).monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((item.isConsumable ? neonRed : neonCyan).opacity(0.2))
                        .foregroundStyle(item.isConsumable ? neonRed : neonCyan)
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(item.description)
                    .font(.callout.weight(.medium).monospaced())
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            // 右側：已安裝狀態標籤 或 價格購買按鈕
            if isInstalled {
                VStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline.weight(.bold))
                    Text("已安裝")
                        .font(.subheadline.weight(.heavy).monospaced())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("INSTALLED")
                        .font(.caption2.weight(.bold).monospaced())
                }
                .foregroundStyle(neonCyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(neonCyan.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(neonCyan.opacity(0.6), lineWidth: 1)
                )
            } else {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        viewModel.buyUpgrade(item)
                    }
                } label: {
                    VStack(spacing: 3) {
                        Text("฿ \(item.cost)")
                            .font(.headline.weight(.heavy).monospaced())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(item == .strikeRepair && viewModel.strikes == 0 ? "無失誤" : "購買安裝")
                            .font(.footnote.weight(.bold).monospaced())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(canBuy ? .black : .white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        canBuy
                            ? LinearGradient(
                                colors: [neonAmber, neonAmber.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(canBuy ? neonAmber : Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canBuy)
                .opacity(canBuy ? 1.0 : 0.5)
            }
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isInstalled ? neonCyan.opacity(0.6) : Color.white.opacity(0.12),
                    lineWidth: isInstalled ? 1.5 : 1
                )
        )
    }

    // MARK: - 底部主按鈕
    /// 點擊後關閉結算商店視窗並推進至下一天值勤
    private var nextDayButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.startNextDay()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.title3.weight(.bold))
                Text("開始第 \(viewModel.day + 1) 天值勤")
                    .font(.title3.weight(.heavy).monospaced())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("// START DAY \(viewModel.day + 1)")
                    .font(.subheadline.weight(.bold).monospaced())
                    .opacity(0.85)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [neonCyan, neonCyan.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonCyan, lineWidth: 1.5)
            )
            .shadow(color: neonCyan.opacity(0.45), radius: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // 建立預覽專用的模擬狀態（含廉政署罰款與可購買裝備）
    let vm = GameViewModel()
    vm.credits = 450
    vm.strikes = 1
    vm.reputation = 40
    vm.auditRisk = 25
    vm.latestReport = DailySummaryReport(
        correctCount: 5,
        mistakeCount: 1,
        baseReward: 500,
        perfectShiftBonus: 0,
        reputationBonus: 50,
        auditResult: .fined(penalty: 250),
        totalEarned: 550
    )
    return DailySummaryShopView(viewModel: vm)
}
