#if os(iOS)
    import SwiftUI
    import UIKit
    import XCTest
    @testable import NutritionHealthCompanion

    /// Diagnostic attachments, not a pixel-baseline or screenshot-testing framework.
    @MainActor
    final class ProductRenderingTests: XCTestCase {
        private struct UnavailableReviewer: OnDeviceReviewing {
            var isAvailable: Bool { false }
            func explain(_ input: ReviewModelInput) async throws -> AIReviewContentDTO {
                throw LocalReviewError.unavailable
            }
        }
        private final class SyntheticBackend: BackendClient {
            func fetchCustomFoods() async throws -> [CustomFoodVersionDTO] { [] }
            func submitBatch(added: [BodyMassSampleDTO], deletions: [DeletedSampleDTO]) async throws -> SyncResponse {
                throw BackendError.retryable("Synthetic preview cannot sync")
            }
            func fetchSyncStatus() async throws -> StatusResponse { throw BackendError.retryable("Synthetic") }
            func fetchDailyNutritionLedger(date: Date, timezone: String) async throws -> DailyNutritionLedgerResponse {
                DailyNutritionLedgerResponse(
                    localDate: "2026-09-12", timezone: "America/New_York",
                    target: DailyNutritionTarget(
                        policyVersionId: UUID(), policyVersion: "synthetic", caloriesKcal: "2400",
                        caloriesGoalKind: "target", proteinG: "130", proteinGoalKind: "floor"), consumedItemCount: 3,
                    knownCaloriesConsumed: "1480", knownProteinGConsumed: "92", remainingKnownCalories: "920",
                    remainingKnownProteinG: "38", nutritionCompleteness: .complete,
                    nutritionAuthorities: [.externalReference],
                    unknownNutrients: [], consumedItems: [], reasonCodes: [])
            }
            func fetchDayPlan(date: Date) async throws -> DayPlanResponse {
                let day = WireDay.string(from: date)
                let lunch = Self.candidate(
                    id: "lunch", name: "Grilled Chicken Grain Bowl", calories: "657.8571428571462",
                    protein: "47.7", sodium: "1567"
                )
                let dinner = Self.candidate(
                    id: "dinner", name: "Salmon Rice Plate", calories: "618.4",
                    protein: "42.2", sodium: "740"
                )
                return .completed(
                    CompletedDayPlan(
                        requestedDate: day, planDate: day, planSha256: "synthetic-plan",
                        inputsFingerprint: "synthetic-inputs",
                        runId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                        versionId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                        plan: DailyPlanArtifact(
                            artifactKind: "daily_plan", planDate: day,
                            policyVersions: PlanPolicyVersions(
                                engine: "synthetic", planner: "synthetic", schedule: "synthetic", target: "synthetic"),
                            menuSnapshotSha256: "synthetic-menu",
                            slots: [
                                Self.slot(context: "lunch", period: "Lunch", window: ["12:00:00", "13:00:00"], candidate: lunch),
                                Self.slot(context: "dinner", period: "Dinner", window: ["17:00:00", "19:00:00"], candidate: dinner),
                            ],
                            status: "ok"),
                        planItems: [
                            PlanItemReference(
                                itemId: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
                                slotIndex: 0, rank: 1, candidateId: "lunch"),
                            PlanItemReference(
                                itemId: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!,
                                slotIndex: 1, rank: 1, candidateId: "dinner"),
                        ],
                        targetPolicy: nil, generatedAt: nil))
            }
            func listConsumption(runId: UUID) async throws -> ConsumptionListResponse {
                ConsumptionListResponse(entries: [])
            }
            func fetchLatestNextMeal() async throws -> NextMealRecommendationResponse {
                throw BackendError.rejected(
                    statusCode: 404, code: "not_generated", detail: "No synthetic recommendation")
            }
            func fetchBodyGoals(asOfDate: Date, timezone: String) async throws -> BodyGoalsResponse {
                await BodyGoalsViewModelTests.summary
            }
            func fetchProgress(asOfDate: Date, timezone: String) async throws -> OwnerProgressResponse {
                try JSONDecoder().decode(OwnerProgressResponse.self, from: ProgressClientTests.payload)
            }
            func fetchRecentTrainingAnalytics(limit: Int) async throws -> TrainingAnalyticsRecentResponse {
                await TrainingViewModelTests.recent
            }
            func fetchExerciseHistory(
                sourceExerciseId: String, sourceSystem: String, asOfDate: Date, timezone: String, limit: Int
            ) async throws -> ExerciseTrainingHistoryResponse {
                Self.coachableHistory
            }
            func fetchReviewSnapshot(asOfDate: Date, timezone: String) async throws -> OnDeviceReviewSnapshot {
                await OnDeviceReviewSnapshot(
                    snapshot: AIReviewViewModelTests.snapshot,
                    modelInput: ReviewModelInput(
                        goal: "gain", weightEvidence: "stale", nutritionEvidence: "recorded_partial",
                        calorieTargetAvailable: true, proteinTargetAvailable: true, nextMeal: "unavailable",
                        includesEstimates: true, limitation: "Only recorded evidence is known."))
            }

            // Two comparable Cable Row sessions: identical top-set load with one
            // extra top-set rep in the latest session, three working sets each,
            // no failure sets, moderate RPE.
            //
            // The coaching block below is NOT authored copy. It is the exact
            // output the production deterministic engine
            // (`domain/training/analytics.py`, `owner-training-coaching.v1`)
            // produces for this evidence: progress / add_one_top_set_rep_same_load
            // with an 11-rep target at the same load. The comparison deltas and
            // volume figures are likewise the engine's computed values.
            private static let coachableHistory = ExerciseTrainingHistoryResponse(
                policyVersion: "owner-training-analytics.v1",
                sourceSystem: "hevy",
                sourceExerciseId: "fixture-row",
                latestDisplayName: "Cable Row",
                history: [latestRowPoint, previousRowPoint],
                latest: latestRowPoint,
                previous: previousRowPoint,
                comparison: ExerciseSessionComparisonDTO(
                    latestRevisionId: "00000000-0000-0000-0000-000000000002",
                    previousRevisionId: "00000000-0000-0000-0000-000000000001",
                    workingSetCountDelta: 0,
                    topLoadDeltaKg: "0E-14",
                    repsAtSameTopLoadDelta: 1,
                    volumeDeltaKgReps: "72.57486550970236",
                    reasonCodes: []
                ),
                frequency: ExerciseFrequencyDTO(
                    timezone: "America/New_York",
                    asOfDate: "2026-09-04",
                    sessionsLast7Days: 1,
                    sessionsLast28Days: 2,
                    daysSinceLastPerformance: 0
                ),
                prEvidence: [],
                completeness: TrainingHistoryCompletenessDTO(
                    sourceBootstrapComplete: true,
                    queryComplete: true,
                    lifetimeGuaranteed: false,
                    wording: "PR within synced Hevy history; Hevy lifetime completeness is not guaranteed."
                ),
                coaching: ExerciseCoachingGuidanceDTO(
                    policyVersion: "owner-training-coaching.v1",
                    analyticsPolicyVersion: "owner-training-analytics.v1",
                    timezone: "America/New_York",
                    asOfDate: "2026-09-04",
                    status: "progress",
                    action: "add_one_top_set_rep_same_load",
                    metricFamily: "rep_load",
                    latestRevisionId: "00000000-0000-0000-0000-000000000002",
                    previousRevisionId: "00000000-0000-0000-0000-000000000001",
                    latestStartedAt: latestRowStartedAt,
                    previousStartedAt: previousRowStartedAt,
                    target: TrainingCoachingTargetDTO(
                        workingSetCount: 3,
                        topLoadKg: "36.28743275485118",
                        topSetReps: 11,
                        totalReps: nil,
                        keepAssistanceConstant: false
                    ),
                    reasonCodes: ["comparable_performance_supports_rep_progression"],
                    limitations: [
                        "advisory_only",
                        "no_form_recovery_or_pain_evidence",
                        "no_program_rep_range_or_equipment_increment",
                        "within_synced_hevy_history_not_lifetime",
                    ]
                )
            )

            private static let previousRowStartedAt = Date(timeIntervalSince1970: 1_788_357_600)
            private static let latestRowStartedAt = Date(timeIntervalSince1970: 1_788_962_400)

            private static let previousRowPoint = rowPoint(
                revision: 1, session: 1, title: "Pull 1", startedAt: previousRowStartedAt,
                topReps: 9, repTotal: 26, volume: "943.47325162613068")
            private static let latestRowPoint = rowPoint(
                revision: 2, session: 2, title: "Pull 2", startedAt: latestRowStartedAt,
                topReps: 10, repTotal: 28, volume: "1016.04811713583304")

            private static func rowPoint(
                revision: Int, session: Int, title: String, startedAt: Date,
                topReps: Int, repTotal: Int, volume: String
            ) -> ExerciseHistoryPointDTO {
                ExerciseHistoryPointDTO(
                    revisionId: "00000000-0000-0000-0000-00000000000\(revision)",
                    sourceSessionId: "session-\(session)",
                    sourceRevision: "revision-\(session)",
                    sessionTitle: title,
                    startedAt: startedAt,
                    displayName: "Cable Row",
                    occurrenceCount: 1,
                    metricFamily: "rep_load",
                    recordedSetCount: 3,
                    workingSetCount: 3,
                    warmupSetCount: 0,
                    unsupportedSetCount: 0,
                    repTotal: repTotal,
                    maxLoadKg: "36.28743275485118",
                    topLoadSet: TopLoadSetEvidenceDTO(
                        setIdentity: "set:0", setIndex: 0, setType: "normal",
                        reps: topReps, loadKg: "36.28743275485118", rpe: "8"),
                    volumeKgReps: volume,
                    maxRpe: "8",
                    metricCompleteness: "complete"
                )
            }

            private static func slot(
                context: String, period: String, window: [String], candidate: PlanCandidate
            ) -> PlanSlot {
                PlanSlot(
                    context: context, menuPeriod: period, status: "ok", window: window,
                    failureReasons: [], rejectionCounts: [:], rejectionDetails: [], candidates: [candidate])
            }

            private static func candidate(
                id: String, name: String, calories: String, protein: String, sodium: String
            ) -> PlanCandidate {
                let foodId = UUID()
                let offeringId = UUID()
                return PlanCandidate(
                    candidateId: id, candidateKind: "single", caloriesKcal: calories,
                    categoryNames: ["Entrees"], configurableEstimate: nil, dietaryTags: [],
                    lines: [
                        PlanLine(
                            categoryName: "Entrees", foodId: foodId, nameNormalized: name,
                            occurrenceOrdinal: 1, offeringId: offeringId, parserVersion: "synthetic",
                            profileContentSha256: "synthetic-profile", servings: "1", sourceMid: id)
                    ],
                    provenance: PlanProvenance(
                        offeringIds: [offeringId], foodIds: [foodId],
                        profileContentSha256s: ["synthetic-profile"]),
                    score: PlanScore(breakdown: [:], total: "0"),
                    totals: PlanNutritionFacts(
                        confidence: "official_published", declaredUnavailable: ["fiber_g"],
                        presences: [
                            "calories_kcal": "known_value", "protein_g": "known_value",
                            "sodium_mg": "known_value",
                        ], publishedZero: [],
                        quantities: [
                            "calories_kcal": calories, "protein_g": protein, "sodium_mg": sodium,
                        ]))
            }
        }

        func testSyntheticProductionScreensLightDarkAndLargeText() async throws {
            let backend = SyntheticBackend()
            let body = BodyGoalsViewModel(backend: backend)
            let targets = TargetReviewViewModel(backend: backend)
            let progress = ProgressViewModel(backend: backend)
            let today = TodayViewModel(backend: backend, cache: DayPlanCache())
            let manual = ManualFoodViewModel(backend: backend)
            let review = AIReviewViewModel(backend: backend, reviewer: UnavailableReviewer())
            let analysis = AIReviewViewModel(backend: backend, reviewer: UnavailableReviewer())
            analysis.activate(subject: "synthetic-demo")
            await analysis.generate()
            let training = TrainingViewModel(backend: backend)
            await training.activate(subject: "synthetic-demo")
            let history = NutritionHistoryViewModel(backend: backend)
            let store = InMemoryStateStore()
            let engine = HealthSyncEngine(
                reading: FakeHealthKitPort(pages: []), backend: backend, store: store, auth: FakeAccessTokenProvider())
            let health = HealthSyncViewModel(engine: engine, backend: backend, store: store)
            await today.activate(subject: "synthetic-demo")
            await body.activate(subject: "synthetic-demo")
            await progress.activate(subject: "synthetic-demo")
            let screens: [(String, AnyView)] = [
                (
                    "today",
                    AnyView(
                        TodayView(
                            viewModel: today, nutritionHistoryViewModel: history, progressViewModel: progress,
                            targetReviewViewModel: targets, bodyGoalsViewModel: body, manualFoodViewModel: manual,
                            aiReviewViewModel: review, healthSyncViewModel: health, subject: "synthetic-demo",
                            onSignOut: {}))
                ),
                (
                    "body-goals",
                    AnyView(
                        NavigationStack {
                            BodyGoalsView(viewModel: body, targetReviewViewModel: targets, subject: "synthetic-demo")
                        })
                ),
                (
                    "progress",
                    AnyView(
                        NavigationStack {
                            OwnerProgressView(
                                viewModel: progress, bodyGoalsViewModel: body, targetReviewViewModel: targets,
                                subject: "synthetic-demo")
                        })
                ),
                (
                    "food",
                    AnyView(
                        NavigationStack {
                            ManualFoodView(
                                viewModel: manual,
                                todayViewModel: today,
                                nutritionHistoryViewModel: history,
                                subject: "synthetic-demo"
                            )
                        })
                ),
                (
                    "training",
                    AnyView(TrainingView(viewModel: TrainingViewModel(backend: backend), subject: "synthetic-demo"))
                ),
                (
                    "settings",
                    AnyView(
                        NavigationStack {
                            SettingsView(
                                appearance: .constant(.dark),
                                healthSyncViewModel: health,
                                notificationViewModel: MealGuidanceNotificationViewModel(),
                                onSignOut: {})
                        })
                ),
                ("review", AnyView(NavigationStack { AIReviewView(viewModel: review, subject: "synthetic-demo") })),
                (
                    "review-analysis",
                    AnyView(NavigationStack { AIReviewView(viewModel: analysis, subject: "synthetic-demo") })
                ),
                (
                    "training-coaching",
                    AnyView(
                        NavigationStack {
                            ExerciseHistoryView(
                                viewModel: training, sourceExerciseId: "fixture-row", sourceSystem: "hevy",
                                displayName: "Cable Row", subject: "synthetic-demo")
                        })
                ),
            ]
            for (mode, color, size) in [
                ("light", ColorScheme.light, DynamicTypeSize.large),
                ("dark", .dark, .large), ("large", .light, .accessibility3),
            ] {
                for (name, view) in screens {
                    let host = UIHostingController(
                        rootView: view.environment(\.colorScheme, color).environment(\.dynamicTypeSize, size))
                    let scene = try XCTUnwrap(
                        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
                    let window = UIWindow(windowScene: scene)
                    window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
                    window.overrideUserInterfaceStyle = color == .dark ? .dark : .light
                    window.rootViewController = host
                    window.makeKeyAndVisible()
                    host.view.frame = window.bounds
                    try await Task.sleep(for: .milliseconds(500))
                    host.view.layoutIfNeeded()
                    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                    }
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "nytr-\(name)-\(mode)-synthetic"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                    XCTAssertGreaterThan(image.size.width, 0)
                    window.isHidden = true
                }
            }
        }
    }
#endif
