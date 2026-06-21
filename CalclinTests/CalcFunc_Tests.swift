// AZFormula_Tests.swift
// AZFormula公開APIの結合テスト

import Testing
import AZFormula

// 現在のアプリターゲット定数も検証に使用する
@testable import Calclin

// パラメータ化テストから参照できるアクセスレベルにする
struct TokenizeCase: Sendable {
    let formula: String
    let expected: [String]
}

let tokenizeCases = [
    TokenizeCase(formula: "12+34", expected: ["12", "+", "34"]),
    TokenizeCase(formula: "(1+2)×3÷4+5*6/7",
                 expected: ["(", "1", "+", "2", ")", "×", "3", "÷", "4", "+", "5", "*", "6", "/", "7"]),
    TokenizeCase(formula: "√25+4", expected: ["√", "25", "+", "4"]),
    TokenizeCase(formula: "-20-5", expected: ["-20", "-", "5"]),
    TokenizeCase(formula: "(20-5)", expected: ["(", "20", "-", "5", ")"]),
    TokenizeCase(formula: "-(20-5)-4×-3÷(-2-1)",
                 expected: ["-", "(", "20", "-", "5", ")", "-", "4", "×", "-3", "÷", "(", "-2", "-", "1", ")"]),
    TokenizeCase(formula: "-100*(20-5)/√4",
                 expected: ["-100", "*", "(", "20", "-", "5", ")", "/", "√", "4"]),
    TokenizeCase(formula: "", expected: []),
    TokenizeCase(formula: "5+-6", expected: ["5", "+", "-6"]),
    TokenizeCase(formula: "10/-5", expected: ["10", "/", "-5"])
]

@Test("数式を正しいトークン列へ分割できる", arguments: tokenizeCases)
func tokenizesFormula(testCase: TokenizeCase) {
    #expect(AZFormula.tokenize(testCase.formula) == testCase.expected)
}

struct RPNCase: Sendable {
    let tokens: [String]
    let expected: [String]
}

let rpnCases = [
    RPNCase(tokens: ["2", "+", "3"], expected: ["2", "3", "+"]),
    RPNCase(tokens: ["5", "+", "4", "-", "3"], expected: ["5", "4", "+", "3", "-"]),
    RPNCase(tokens: ["5", "+", "4", "*", "3"], expected: ["5", "4", "3", "*", "+"]),
    RPNCase(tokens: ["5", "+", "(", "4", "*", "3", ")"], expected: ["5", "4", "3", "*", "+"]),
    RPNCase(tokens: ["(", "5", "+", "4", ")", "*", "3"], expected: ["5", "4", "+", "3", "*"]),
    RPNCase(tokens: ["2", "+", "(", "3", "*", "4", ")"], expected: ["2", "3", "4", "*", "+"]),
    RPNCase(tokens: ["-3", "+", "4", "*", "-2", "-", "6", "/", "3"],
            expected: ["-3", "4", "-2", "*", "+", "6", "3", "/", "-"])
]

@Test("トークン列を正しい逆ポーランド記法へ変換できる", arguments: rpnCases)
func convertsTokensToRPN(testCase: RPNCase) {
    #expect(AZFormula.toRPN(testCase.tokens) == testCase.expected)
}

struct EvaluationCase: Sendable {
    let formula: String
    let tokens: [String]
    let rpn: [String]
    let answer: String
}

let evaluationCases = [
    EvaluationCase(formula: "5--6", tokens: ["5", "-", "-6"], rpn: ["5", "-6", "-"], answer: "11"),
    EvaluationCase(formula: "-5--6-2", tokens: ["-5", "-", "-6", "-", "2"],
                   rpn: ["-5", "-6", "-", "2", "-"], answer: "-1"),
    EvaluationCase(formula: "-(20-5)", tokens: ["-", "(", "20", "-", "5", ")"],
                   rpn: ["0", "20", "5", "-", "-"], answer: "-15"),
    EvaluationCase(formula: "100+5%", tokens: ["100", "×", "(", "100", "+", "5", ")", "÷", "100"],
                   rpn: ["100", "100", "5", "+", "×", "100", "÷"], answer: "105"),
    EvaluationCase(formula: "100-5%", tokens: ["100", "×", "(", "100", "-", "5", ")", "÷", "100"],
                   rpn: ["100", "100", "5", "-", "×", "100", "÷"], answer: "95"),
    EvaluationCase(formula: "100×5%", tokens: ["100", "×", "5", "÷", "100"],
                   rpn: ["100", "5", "×", "100", "÷"], answer: "5"),
    EvaluationCase(formula: "100÷5%", tokens: ["100", "÷", "5", "×", "100"],
                   rpn: ["100", "5", "÷", "100", "×"], answer: "2000")
]

@Test("トークン分割から数式評価まで一貫して処理できる", arguments: evaluationCases)
func evaluatesFormulaEndToEnd(testCase: EvaluationCase) throws {
    #expect(AZFormula.tokenize(testCase.formula) == testCase.tokens)
    #expect(AZFormula.toRPN(testCase.tokens) == testCase.rpn)
    #expect(try AZFormula.evaluate(testCase.formula).get() == testCase.answer)
}

@Test("上限を超える数式を拒否する")
func rejectsFormulaOverLengthLimit() {
    let formula = String(repeating: "1", count: FORMULA_LENGTH_MAX + 1)
    guard case .failure(.tooLong) = AZFormula.evaluate(formula) else {
        Issue.record("長すぎる数式がtooLongにならない")
        return
    }
}

@Test("数式に含まれる無効文字を除外する")
func filtersInvalidFormulaCharacters() throws {
    let actual = try AZFormula.evaluate("1a+2$").get()
    let expected = try AZFormula.evaluate("1+2").get()
    #expect(actual == expected)
}
