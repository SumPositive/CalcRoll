// CalclinTests.swift
// テストターゲットの基本確認

import Testing

// 現在のアプリターゲットをテストする
@testable import Calclin

@Test("テスト環境を起動できる")
func loadsTestEnvironment() {
    #expect(FORMULA_LENGTH_MAX == 200)
}
