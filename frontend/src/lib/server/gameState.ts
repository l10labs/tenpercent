interface Player {
	id: string;
	name: string;
	points: number;
	currentSquare: number | null;
	movesLeft: number;
	movesMade: number;
}

interface Square {
	totalPoints: number;
	players: Set<string>;
}

interface GameState {
	players: Map<string, Player>;
	squares: Square[];
	isActive: boolean;
	isFinished: boolean;
	winningSquare: number | null;
}

class GameStateManager {
	private static instance: GameStateManager;
	private gameState: GameState;

	private constructor() {
		this.gameState = {
			players: new Map(),
			squares: Array(4)
				.fill(null)
				.map(() => ({
					totalPoints: 0,
					players: new Set()
				})),
			isActive: false,
			isFinished: false,
			winningSquare: null
		};
	}

	public static getInstance(): GameStateManager {
		if (!GameStateManager.instance) {
			GameStateManager.instance = new GameStateManager();
		}
		return GameStateManager.instance;
	}

	public addPlayer(playerId: string, name: string) {
		this.gameState.players.set(playerId, {
			id: playerId,
			name,
			points: 10,
			currentSquare: null,
			movesLeft: 10,
			movesMade: 0
		});

		if (this.gameState.players.size >= 2 && !this.gameState.isActive) {
			this.gameState.isActive = true;
		}
	}

	public makeMove(playerId: string, squareIndex: number) {
		const player = this.gameState.players.get(playerId);
		if (!player || player.movesLeft <= 0) return false;

		// Remove points from previous square if any
		if (player.currentSquare !== null) {
			this.gameState.squares[player.currentSquare].totalPoints -= player.points;
			this.gameState.squares[player.currentSquare].players.delete(playerId);
		}

		// Add points to new square
		this.gameState.squares[squareIndex].totalPoints += player.points;
		this.gameState.squares[squareIndex].players.add(playerId);
		player.currentSquare = squareIndex;
		player.movesLeft--;
		player.movesMade++;

		this.checkGameEnd();
		return true;
	}

	private checkGameEnd() {
		const allPlayersMinMoves = Array.from(this.gameState.players.values()).every(
			(player) => player.movesMade >= 5
		);

		if (allPlayersMinMoves) {
			this.gameState.isFinished = true;
			this.determineWinner();
		}
	}

	private determineWinner() {
		let maxPoints = -1;
		let losingSquare = 0;

		this.gameState.squares.forEach((square, index) => {
			if (square.totalPoints > maxPoints) {
				maxPoints = square.totalPoints;
				losingSquare = index;
			}
		});

		this.gameState.winningSquare = losingSquare;
	}

	public getGameState(): GameState {
		return this.gameState;
	}
}

export const gameStateManager = GameStateManager.getInstance();

// This implementation includes:

// 1. A server-side game state manager that:
//    - Tracks players and their points:
//    - Manages the squares and their total points
//    - Handles game logic and win conditions
//    - Keeps track of moves

// 2. A user interface that:
//    - Allows players to join the game
//    - Shows the current game state
//    - Displays player information
//    - Shows square information
//    - Updates in real-time
//    - Indicates winning and losing squares

// 3. Game features:
//    - Players start with 10 points
//    - Players can make up to 10 moves
//    - Game starts with 2 players
//    - Players can join mid-game
//    - Game ends when all players make at least 5 moves
//    - Square with most points loses

// To run this:

// 1. Create a new SvelteKit project
// 2. Copy these files into their respective locations
// 3. Run `npm install`
// 4. Run `npm run dev`

// The game will be available at `http://localhost:5173/`

// You can enhance this further by:
// - Adding animations
// - Improving the UI design
// - Adding sound effects
// - Adding player statistics
// - Adding a chat feature
// - Adding a leaderboard
// - Adding game history
