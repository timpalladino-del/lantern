import XCTest
@testable import Lantern

final class GamesTests: XCTestCase {

    func testTicTacToeRowWin() {
        var g = TicTacToe()
        g.play(0); g.play(3); g.play(1); g.play(4); g.play(2)
        XCTAssertEqual(g.winner, .x)
        XCTAssertEqual(g.winningLine, [0, 1, 2])
        XCTAssertTrue(g.isOver)
        XCTAssertFalse(g.play(5), "no moves after a win")
    }

    func testTicTacToeDiagonalAndDraw() {
        var g = TicTacToe()
        g.play(0); g.play(1); g.play(4); g.play(2); g.play(8)
        XCTAssertEqual(g.winner, .x)
        var d = TicTacToe()
        for i in [0, 1, 2, 4, 3, 5, 7, 6, 8] { XCTAssertTrue(d.play(i)) }
        XCTAssertNil(d.winner)
        XCTAssertTrue(d.isDraw)
    }

    func testTicTacToeRejectsBadMoves() {
        var g = TicTacToe()
        XCTAssertTrue(g.play(4))
        XCTAssertFalse(g.play(4))
        XCTAssertFalse(g.play(9))
        XCTAssertEqual(g.turn, .o)
    }

    func testFourInARowVerticalWin() {
        var g = FourInARow()
        for _ in 0..<3 { g.drop(0); g.drop(1) }
        XCTAssertNil(g.winner)
        g.drop(0)
        XCTAssertEqual(g.winner, .a)
        XCTAssertFalse(g.canDrop(3), "board locks after a win")
    }

    func testFourInARowDiagonalWin() {
        var g = FourInARow()
        // a at (0,0),(1,1),(2,2),(3,3) with b filler
        g.drop(0)            // a (0,0)
        g.drop(1); g.drop(1) // b (1,0), a (1,1)
        g.drop(2); g.drop(3); g.drop(2) // b (2,0), a (3,0), b (2,1)
        g.drop(2)            // a (2,2)
        g.drop(3); g.drop(3) // b (3,1), a (3,2)
        g.drop(6)            // b elsewhere
        g.drop(3)            // a (3,3)
        XCTAssertEqual(g.winner, .a)
        XCTAssertEqual(g.winningCells?.cells.count, 4)
    }

    func testFourInARowColumnFills() {
        var g = FourInARow()
        for _ in 0..<FourInARow.rows { XCTAssertTrue(g.drop(4)) }
        XCTAssertFalse(g.canDrop(4))
        XCTAssertFalse(g.drop(4))
    }

    func testHangman() {
        var h = Hangman(word: "ice cream")
        XCTAssertEqual(h.masked, "_ _ _ / _ _ _ _ _")
        XCTAssertTrue(h.guess("e"))
        XCTAssertEqual(h.masked, "_ _ E / _ _ E _ _")
        XCTAssertFalse(h.guess("e"), "repeat guess ignored")
        XCTAssertFalse(h.guess("1"), "non-letters ignored")
        for c in "xyzqjk" { h.guess(c) }
        XCTAssertTrue(h.isLost)
        XCTAssertEqual(h.missesLeft, 0)
        var w = Hangman(word: "owl")
        for c in "lwo" { w.guess(c) }
        XCTAssertTrue(w.isWon)
        XCTAssertEqual(w.misses, 0)
    }

    func testNumberGuess() {
        var n = NumberGuess(secret: 42)
        XCTAssertEqual(n.guess(10), .low)
        XCTAssertEqual(n.guess(80), .high)
        XCTAssertEqual(n.guess(42), .right)
        XCTAssertTrue(n.isWon)
        XCTAssertEqual(n.guesses.count, 3)
    }

    func testSimonSequence() {
        var s = SimonGame()
        s.extend(); s.extend()
        let a = s.sequence[0], b = s.sequence[1]
        XCTAssertEqual(s.press(a), .more)
        XCTAssertEqual(s.press(b), .roundDone)
        XCTAssertEqual(s.bestRound, 2)
        XCTAssertEqual(s.press(a), .more, "extra taps after a finished round are ignored")
        s.extend()
        XCTAssertEqual(s.press((s.sequence[0] + 1) % 4), .wrong)
    }

    func testRockPaperScissors() {
        XCTAssertEqual(RPS.rock.versus(.scissors), 1)
        XCTAssertEqual(RPS.scissors.versus(.rock), -1)
        XCTAssertEqual(RPS.paper.versus(.paper), 0)
        for a in RPS.allCases { for b in RPS.allCases { XCTAssertEqual(a.versus(b), -b.versus(a)) } }
    }

    func testTriviaBankIsSound() {
        let qs = GamesLibrary.questions
        XCTAssertGreaterThanOrEqual(qs.count, 60)
        XCTAssertEqual(Set(qs.map(\.id)).count, qs.count, "ids unique")
        XCTAssertEqual(Set(qs.map(\.prompt)).count, qs.count, "prompts unique")
        for q in qs {
            XCTAssertEqual(q.options.count, 4, q.id)
            XCTAssertTrue((0..<4).contains(q.answer), q.id)
            XCTAssertEqual(Set(q.options).count, 4, "\(q.id) options unique")
            XCTAssertFalse(q.note.isEmpty, q.id)
            XCTAssertFalse(q.prompt.contains("—"), "\(q.id) no em dashes")
        }
        let round = GamesLibrary.quizRound()
        XCTAssertEqual(round.count, 10)
        XCTAssertEqual(Set(round.map(\.id)).count, 10)
        XCTAssertEqual(round.filter(\.readiness).count, 5)
    }

    func testWordBanks() {
        for c in GamesLibrary.categories {
            XCTAssertGreaterThanOrEqual(c.words.count, 30, c.id)
            XCTAssertEqual(Set(c.words).count, c.words.count, "\(c.id) words unique")
        }
        XCTAssertEqual(Set(GamesLibrary.categories.map(\.id)).count, GamesLibrary.categories.count)
        XCTAssertGreaterThanOrEqual(GamesLibrary.wouldYouRather.count, 50)
        XCTAssertGreaterThanOrEqual(GamesLibrary.storyStarters.count, 25)
        XCTAssertGreaterThanOrEqual(GamesLibrary.storyTwists.count, 25)
        XCTAssertGreaterThanOrEqual(GamesLibrary.huntPrompts.count, 30)
        XCTAssertGreaterThanOrEqual(GamesLibrary.puppets.count, 8)
        XCTAssertGreaterThanOrEqual(GamesLibrary.hangmanWords.count, 200)
        XCTAssertTrue(GamesLibrary.hangmanWords.allSatisfy { $0.word.allSatisfy { $0.isLetter || $0 == " " } })
        XCTAssertGreaterThanOrEqual(GamesLibrary.secretThings.count, 100)
        let banned = ["prepper", "survival", "SHTF", "bug out", "tactical", "doomsday"]
        let all = (GamesLibrary.categories.flatMap(\.words) + GamesLibrary.storyStarters + GamesLibrary.storyTwists + GamesLibrary.huntPrompts
                   + GamesLibrary.wouldYouRather.flatMap { [$0.0, $0.1] } + GamesLibrary.questions.flatMap { [$0.prompt, $0.note] + $0.options }).joined(separator: " ").lowercased()
        for b in banned { XCTAssertFalse(all.contains(b.lowercased()), "banned word: \(b)") }
        XCTAssertFalse(all.contains("—"), "no em dashes in game copy")
    }

    @MainActor
    func testStatusTextsFillIn() throws {
        let container = try AppSchema.container(inMemory: true)
        let ctx = container.mainContext
        let h = Household()
        ctx.insert(h)
        let a = Person(name: "Tim"); ctx.insert(a)
        let b = Person(name: "Maria"); ctx.insert(b)
        h.people = [a, b]
        try ctx.save()
        let o = OutageEvent(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let p = HouseholdPlan(); p.meetNearHome = "the mailbox"; p.meetOutsideNeighborhood = "the library lot"
        let msgs = StatusTextsView.messages(household: h, outage: o, plan: p, now: Date())
        XCTAssertEqual(msgs.count, 6)
        let safe = try XCTUnwrap(msgs.first { $0.id == "safe" })
        XCTAssertTrue(safe.body.hasPrefix("Tim and Maria are safe"), safe.body)
        XCTAssertTrue(safe.body.contains("Power's out since"), safe.body)
        XCTAssertTrue(msgs.first { $0.id == "meet" }!.body.contains("the mailbox"))
        XCTAssertTrue(msgs.first { $0.id == "leaving" }!.body.contains("the library lot"))
        let bare = StatusTextsView.messages(household: nil, outage: nil, plan: nil, now: Date())
        XCTAssertEqual(bare.count, 5)
        XCTAssertTrue(bare[0].body.hasPrefix("We're safe"))
        XCTAssertFalse(bare[0].body.contains("since"))
    }
}
