//
//  File.swift
//  CardServer
//
//  Created by 高橋沙久哉 on 2025/02/14.
//

//
//  File.swift
//  cardData
//
//  Created by 高橋沙久哉 on 2025/01/14.
//

import Foundation
import Vapor
import Fluent
struct CardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("api","card", use: createHandler)
        routes.get("api","card",use: allGetHandler)
        routes.delete("api","users",":userID",use: deletHandler)
        routes.get("searchCard",use:searchCard)
    }
    func createHandler(req: Request) async throws -> CardModels {
        let card = try req.content.decode(CardModels.self)
        print(card)
        try await card.save(on: req.db)
        return card
    }
    func allGetHandler(req: Request) async throws -> [CardModels] {
        let cards = try await CardModels.query(on: req.db).all()
        return cards
    }
    func searchCard(req: Request) async throws -> [CardModels] {
        let queryObuj = CardModels.query(on: req.db)
        // クエリパラメータを取得
        if let name = req.parameters.get("name") {
            let katakanaString = name.applyingTransform(.hiraganaToKatakana, reverse: false)
            if let katakanaString {
                queryObuj.filter(\CardModels.$name ~~ katakanaString)
            }
        }
        if let attribute = req.parameters.get("attribute") {
            queryObuj.filter(\CardModels.$attribute == attribute)
        }
        if let lebel = req.parameters.get("lebel") {
            queryObuj.filter(\CardModels.$lebel == lebel)
        }
        if let race = req.parameters.get("race") {
            queryObuj.filter(\CardModels.$race == race)
        }
        if let trueName = req.parameters.get("name") {    //正式名称で検索したプレイヤーにヒットさせるため
            queryObuj.filter(\CardModels.$trueName == trueName)
        }
        if let description = req.parameters.get("description") {
            queryObuj.filter(\CardModels.$description ~~ description) //~~: 部分一致演算子(論理和)
        }
        if let searchTag = req.parameters.get("searchTag") {
            queryObuj.filter(\CardModels.$searchTag == searchTag)
        }
        // 結果を取得
        return try await queryObuj.all()
    }
    func deletHandler(req: Request) async throws -> HTTPStatus {
        guard let user = try await CardModels.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .ok
    }
}
