//
//  ContentView.swift
//  Checkers
//
//  Created by Heather Scheer on 11/27/24.
//

import SwiftUI

    enum PlayerType {
        case human, computer
    }

    enum PieceColor {
        case red, black
        
        var opposite: PieceColor {
            return self == .red ? .black : .red
        }
    }

    struct CheckersPiece: Identifiable {
        let id = UUID()
        var position: BoardPosition
        let color: PieceColor
        var isKing: Bool = false
    }

    struct BoardPosition: Hashable {
        let x: Int
        let y: Int
    }

    class CheckersGame: ObservableObject {
        @Published var board: [[CheckersPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        @Published var currentPlayer: PieceColor = .red
        @Published var selectedPiece: CheckersPiece?
        
        init() {
            setupInitialBoard()
        }
        
        func setupInitialBoard() {
            // Setup red pieces
            for y in 0...2 {
                for x in 0...7 {
                    if (x + y) % 2 == 1 {
                        board[y][x] = CheckersPiece(position: BoardPosition(x: x, y: y), color: .red)
                    }
                }
            }
            
            // Setup black pieces
            for y in 5...7 {
                for x in 0...7 {
                    if (x + y) % 2 == 1 {
                        board[y][x] = CheckersPiece(position: BoardPosition(x: x, y: y), color: .black)
                    }
                }
            }
        }
        
        func movePiece(from start: BoardPosition, to end: BoardPosition) {
            guard let piece = board[start.y][start.x] else { return }
            
            // Remove piece from start position
            board[start.y][start.x] = nil
            
            // Check if it's a jump move and remove jumped piece
            let jumpedX = (start.x + end.x) / 2
            let jumpedY = (start.y + end.y) / 2
            
            if abs(start.x - end.x) == 2 {
                board[jumpedY][jumpedX] = nil
            }
            
            // Place piece in new position
            board[end.y][end.x] = piece
            
            // Check for king promotion
            if (piece.color == .red && end.y == 7) || (piece.color == .black && end.y == 0) {
                board[end.y][end.x]?.isKing = true
            }
            
            // Switch player
            currentPlayer = currentPlayer.opposite
        }
        
        func isValidMove(from start: BoardPosition, to end: BoardPosition) -> Bool {
            guard let piece = board[start.y][start.x] else { return false }
            
            let dx = end.x - start.x
            let dy = end.y - start.y
            
            // Check basic move rules
            let isForwardMove = piece.color == .red ? dy > 0 : dy < 0
            let isDiagonalMove = abs(dx) == 1 && abs(dy) == 1
            let isJumpMove = abs(dx) == 2 && abs(dy) == 2
            
            // Check if destination is empty
            guard board[end.y][end.x] == nil else { return false }
            
            // Regular move
            if !piece.isKing && isDiagonalMove && isForwardMove {
                return true
            }
            
            // Jump move
            if isJumpMove {
                let jumpedX = (start.x + end.x) / 2
                let jumpedY = (start.y + end.y) / 2
                
                guard let jumpedPiece = board[jumpedY][jumpedX],
                      jumpedPiece.color != piece.color else { return false }
                
                return true
            }
            
            return false
        }
    }

    struct CheckersBoardView: View {
        @StateObject private var game = CheckersGame()
        
        var body: some View {
            VStack {
                Text("Checkers Game")
                    .font(.title)
                
                Text("Current Player: \(game.currentPlayer == .red ? "Red" : "Black")")
                    .padding()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { y in
                            HStack(spacing: 0) {
                                ForEach(0..<8, id: \.self) { x in
                                    SquareView(game: game, position: BoardPosition(x: x, y: y))
                                        .frame(width: geometry.size.width / 8,
                                               height: geometry.size.width / 8)
                                }
                            }
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding()
            }
        }
    }

    struct SquareView: View {
        @ObservedObject var game: CheckersGame
        let position: BoardPosition
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill((position.x + position.y) % 2 == 0 ? Color.white : Color.gray)
                    .onTapGesture {
                        handleSquareTap()
                    }
                
                if let piece = game.board[position.y][position.x] {
                    Circle()
                        .fill(piece.color == .red ? Color.red : Color.black)
                        .padding(5)
                        .overlay(
                            Group {
                                if piece.isKing {
                                    Text("K")
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                }
                            }
                        )
                }
            }
        }
        
        func handleSquareTap() {
            if let selectedPiece = game.selectedPiece {
                if game.isValidMove(from: selectedPiece.position, to: position) {
                    game.movePiece(from: selectedPiece.position, to: position)
                    game.selectedPiece = nil
                } else {
                    // Invalid move, reset selection
                    game.selectedPiece = nil
                }
            } else if let piece = game.board[position.y][position.x],
                      piece.color == game.currentPlayer {
                game.selectedPiece = piece
            }
        }
    }

    struct ContentView: View {
        var body: some View {
            CheckersBoardView()
        }
    }

#Preview {
    ContentView()
}
