import Foundation

// Pure game rules, kept out of the views so they can be tested.

/// Three-by-three, X goes first. Cells are 0...8, row-major.
struct TicTacToe: Equatable {
    enum Mark: String { case x = "X", o = "O" }
    var cells: [Mark?] = Array(repeating: nil, count: 9)
    var turn: Mark = .x

    static let lines: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    var winner: Mark? {
        for l in TicTacToe.lines {
            if let m = cells[l[0]], cells[l[1]] == m, cells[l[2]] == m { return m }
        }
        return nil
    }
    var winningLine: [Int]? { TicTacToe.lines.first { l in cells[l[0]] != nil && cells[l[0]] == cells[l[1]] && cells[l[1]] == cells[l[2]] } }
    var isDraw: Bool { winner == nil && cells.allSatisfy { $0 != nil } }
    var isOver: Bool { winner != nil || isDraw }

    /// Returns false when the move is not allowed.
    @discardableResult
    mutating func play(_ i: Int) -> Bool {
        guard !isOver, (0..<9).contains(i), cells[i] == nil else { return false }
        cells[i] = turn
        turn = turn == .x ? .o : .x
        return true
    }
}

/// Seven columns, six rows. Pieces drop to the lowest empty row. Row 0 is the bottom.
struct FourInARow: Equatable {
    enum Piece: String { case a, b }
    static let columns = 7, rows = 6
    var grid: [[Piece?]] = Array(repeating: Array(repeating: nil, count: FourInARow.rows), count: FourInARow.columns) // grid[column][row]
    var turn: Piece = .a
    var lastDrop: (column: Int, row: Int)?

    static func == (l: FourInARow, r: FourInARow) -> Bool { l.grid == r.grid && l.turn == r.turn }

    func canDrop(_ c: Int) -> Bool { (0..<FourInARow.columns).contains(c) && grid[c][FourInARow.rows - 1] == nil && winner == nil }

    @discardableResult
    mutating func drop(_ c: Int) -> Bool {
        guard canDrop(c), let r = grid[c].firstIndex(where: { $0 == nil }) else { return false }
        grid[c][r] = turn
        lastDrop = (c, r)
        turn = turn == .a ? .b : .a
        return true
    }

    var isFull: Bool { grid.allSatisfy { $0.allSatisfy { $0 != nil } } }

    var winner: Piece? { winningCells?.piece }

    var winningCells: (piece: Piece, cells: [(Int, Int)])? {
        let dirs = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for c in 0..<FourInARow.columns {
            for r in 0..<FourInARow.rows {
                guard let p = grid[c][r] else { continue }
                for (dc, dr) in dirs {
                    var cells = [(c, r)]
                    var cc = c + dc, rr = r + dr
                    while cc >= 0, cc < FourInARow.columns, rr >= 0, rr < FourInARow.rows, grid[cc][rr] == p {
                        cells.append((cc, rr)); cc += dc; rr += dr
                    }
                    if cells.count >= 4 { return (p, cells) }
                }
            }
        }
        return nil
    }
}

/// Classic word guess. Six wrong guesses lose.
struct Hangman: Equatable {
    let word: String          // uppercase letters and spaces
    var guessed: Set<Character> = []
    static let maxMisses = 6

    init(word: String) { self.word = word.uppercased() }

    var misses: Int { guessed.filter { !word.contains($0) }.count }
    var missesLeft: Int { Hangman.maxMisses - misses }
    var isWon: Bool { word.allSatisfy { $0 == " " || guessed.contains($0) } }
    var isLost: Bool { misses >= Hangman.maxMisses }
    var isOver: Bool { isWon || isLost }

    /// "C_T" style display, a space between letters, a slash for a word break.
    var masked: String {
        word.map { ch -> String in
            if ch == " " { return "/" }
            return guessed.contains(ch) ? String(ch) : "_"
        }.joined(separator: " ")
    }

    @discardableResult
    mutating func guess(_ c: Character) -> Bool {
        let u = Character(c.uppercased())
        guard !isOver, u.isLetter, !guessed.contains(u) else { return false }
        guessed.insert(u)
        return true
    }
}

/// Higher or lower, 1 to 100.
struct NumberGuess: Equatable {
    let secret: Int
    var guesses: [Int] = []
    init(secret: Int = Int.random(in: 1...100)) { self.secret = secret }
    enum Result { case low, high, right }
    mutating func guess(_ n: Int) -> Result {
        guesses.append(n)
        if n < secret { return .low }
        if n > secret { return .high }
        return .right
    }
    var isWon: Bool { guesses.last == secret }
}

/// Repeat-the-pattern memory game over four pads.
struct SimonGame: Equatable {
    var sequence: [Int] = []
    var input: [Int] = []
    var bestRound = 0

    var round: Int { sequence.count }

    mutating func extend() {
        sequence.append(Int.random(in: 0..<4))
        input = []
    }

    enum Step { case more, roundDone, wrong }
    mutating func press(_ pad: Int) -> Step {
        guard input.count < sequence.count else { return .more }   // round already complete; ignore extra taps
        input.append(pad)
        let i = input.count - 1
        if sequence[i] != pad { return .wrong }
        if input.count == sequence.count { bestRound = max(bestRound, round); return .roundDone }
        return .more
    }

    mutating func reset() { sequence = []; input = [] }
}

/// Rock, paper, scissors against the phone.
enum RPS: String, CaseIterable, Identifiable {
    case rock = "Rock", paper = "Paper", scissors = "Scissors"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .rock: return "circle.fill"; case .paper: return "doc.fill"; case .scissors: return "scissors" }
    }
    /// 1 if self beats other, -1 if it loses, 0 for a tie.
    func versus(_ other: RPS) -> Int {
        if self == other { return 0 }
        switch (self, other) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper): return 1
        default: return -1
        }
    }
}
