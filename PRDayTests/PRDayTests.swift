import XCTest
@testable import PRDay

final class WBGTEngineTests: XCTestCase {
    func testGreenFlag() {
        let result = WBGTEngine.compute(tempF: 75, humidity: 40)
        XCTAssertEqual(result.flag, .green)
    }

    func testYellowFlag() {
        let result = WBGTEngine.compute(tempF: 84, humidity: 60)
        XCTAssertEqual(result.flag, .yellow)
    }

    func testOrangeFlag() {
        let result = WBGTEngine.compute(tempF: 86, humidity: 65)
        XCTAssertEqual(result.flag, .orange)
    }

    func testRedFlag() {
        let result = WBGTEngine.compute(tempF: 88, humidity: 65)
        XCTAssertEqual(result.flag, .red)
    }

    func testBlackFlag() {
        let result = WBGTEngine.compute(tempF: 90, humidity: 70)
        XCTAssertEqual(result.flag, .black)
    }

    func testExtremeHeatIsBlack() {
        let result = WBGTEngine.compute(tempF: 105, humidity: 90)
        XCTAssertEqual(result.flag, .black)
        XCTAssertGreaterThanOrEqual(result.wbgtF, 92.2)
    }
}

final class PaceEngineTests: XCTestCase {
    func testRiegelMonotonic() {
        let t1600 = PaceEngine.riegel(t1Sec: 300, d1Meters: 800, d2Meters: 1600)
        XCTAssertGreaterThan(t1600, 300)
        let t3200 = PaceEngine.riegel(t1Sec: t1600, d1Meters: 1600, d2Meters: 3200)
        XCTAssertGreaterThan(t3200, t1600)
    }

    func testRiegelKnownValue() {
        let predicted = PaceEngine.riegel(t1Sec: 240, d1Meters: 1600, d2Meters: 3200)
        XCTAssertEqual(predicted, 240 * pow(2, 1.06), accuracy: 0.001)
    }

    func testTrainingPacesOrdering() {
        let paces = PaceEngine.trainingPaces(prSec: 300, prMeters: 1600)
        XCTAssertLessThan(paces.repPaceSecPerMile, paces.intervalPaceSecPerMile)
        XCTAssertLessThan(paces.intervalPaceSecPerMile, paces.thresholdPaceSecPerMile)
        XCTAssertLessThan(paces.thresholdPaceSecPerMile, paces.easyPaceSecPerMile)
    }

    func testFormatSeconds() {
        XCTAssertEqual(PaceEngine.formatSeconds(61.5), "1:01.50")
        XCTAssertEqual(PaceEngine.formatSeconds(9.99), "9.99")
    }
}

final class StreakEngineTests: XCTestCase {
    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Calendar.current.startOfDay(for: Date.now))!
    }

    func testConsecutiveStreak() {
        let streak = StreakEngine.currentStreak(sessionDays: [daysAgo(2), daysAgo(1), daysAgo(0)], makeupDays: [])
        XCTAssertEqual(streak, 3)
    }

    func testGapBreaksStreak() {
        let streak = StreakEngine.currentStreak(sessionDays: [daysAgo(5), daysAgo(1)], makeupDays: [])
        XCTAssertEqual(streak, 1)
    }

    func testMakeupRestoresStreak() {
        let streak = StreakEngine.currentStreak(sessionDays: [daysAgo(3), daysAgo(1)], makeupDays: [daysAgo(2)])
        XCTAssertEqual(streak, 3)
    }

    func testLongestStreakSurvivesGaps() {
        let longest = StreakEngine.longestStreak(sessionDays: [daysAgo(10), daysAgo(9), daysAgo(8), daysAgo(1)], makeupDays: [])
        XCTAssertEqual(longest, 3)
    }

    func testMakeupWindowValid() {
        XCTAssertNotNil(StreakEngine.makeupWindowDays(lastDay: daysAgo(2)))
        XCTAssertNil(StreakEngine.makeupWindowDays(lastDay: daysAgo(8)))
    }
}

final class PlanEngineTests: XCTestCase {
    func testAllGroupsGenerateFullPlan() {
        for group in EventGroup.allCases {
            let profile = AthleteProfile()
            profile.eventGroup = group
            let weeks = PlanEngine.generate(profile: profile, bestRuns: ["1600m": 300])
            XCTAssertEqual(weeks.count, 12)
            XCTAssertEqual(weeks.flatMap { $0.days }.count, 84)
            XCTAssertFalse(weeks[0].days[0].blocks.isEmpty)
        }
    }

    func testTaperReducesVolume() {
        let profile = AthleteProfile()
        let weeks = PlanEngine.generate(profile: profile, bestRuns: [:])
        let taperDay = weeks[11].days[0]
        XCTAssertTrue(taperDay.blocks.contains { $0.detail.contains("reduced") })
    }

    func testPacesResolvedForMidDistance() {
        let profile = AthleteProfile()
        profile.eventGroup = .midDistance
        let weeks = PlanEngine.generate(profile: profile, bestRuns: ["1600m": 300])
        let intervalDay = weeks[0].days[0]
        XCTAssertTrue(intervalDay.blocks.contains { $0.targetPace?.contains("/mi") == true })
    }

    func testDaysToRace() {
        let race = Calendar.current.date(byAdding: .day, value: 7, to: Date.now)
        let days = PlanEngine.daysToRace(race)
        XCTAssertEqual(days, 7)
    }
}

final class PlanAdjustmentEngineTests: XCTestCase {
    private func baseDay(intensity: PlanDay.Intensity) -> PlanDay {
        PlanDay(id: "w1d1", week: 1, dayOfWeek: 1, date: Date.now, title: "Speed Day", focus: "Speed", intensity: intensity, blocks: [], workRestRatio: nil, extraBreaksPerHour: nil, indoorOnly: false, volumeScale: 1, note: nil)
    }

    func testGreenNoChange() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .high), flag: .green, daysToRace: nil)
        XCTAssertEqual(adjusted.title, "Speed Day")
        XCTAssertFalse(adjusted.indoorOnly)
    }

    func testYellowAddsBreaks() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .moderate), flag: .yellow, daysToRace: nil)
        XCTAssertEqual(adjusted.workRestRatio, "2:1")
        XCTAssertEqual(adjusted.extraBreaksPerHour, 3)
    }

    func testOrangeRewritesHighIntensity() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .high), flag: .orange, daysToRace: nil)
        XCTAssertTrue(adjusted.title.contains("heat-adjusted"))
        XCTAssertEqual(adjusted.workRestRatio, "1:1")
    }

    func testRedForcesIndoor() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .high), flag: .red, daysToRace: nil)
        XCTAssertTrue(adjusted.indoorOnly)
    }

    func testTaperReducesVolumeNearRace() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .high), flag: .green, daysToRace: 5)
        XCTAssertEqual(adjusted.volumeScale, 0.6)
        XCTAssertTrue(adjusted.note?.contains("Taper") == true)
    }

    func testNoTaperFarFromRace() {
        let adjusted = PlanAdjustmentEngine.adjust(day: baseDay(intensity: .high), flag: .green, daysToRace: 30)
        XCTAssertEqual(adjusted.volumeScale, 1)
    }
}
