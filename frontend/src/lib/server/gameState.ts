import type { Player, Square, GameResult, GameState } from '$lib/types';

export class Game {
	private squares: Square[] = [];
	private lobby: Set<Player> = new Set();
	private bombCounter: number = 5;
	private roundNumber: number = 1; // Added to track rounds

	constructor() {
		this.initializeSquares();
	}

	private initializeSquares(): void {
		this.squares = [];
		for (let i = 0; i < 4; i++) {
			this.squares.push({
				players: new Set<Player>(),
				totalBalancePoints: 0
			});
		}
	}

	private findPlayerByName(name: string): Player | null {
		for (const player of this.lobby) {
			if (player.name === name) {
				return player;
			}
		}
		return null;
	}

	private validatePlayerName(name: string): void {
		if (!name || typeof name !== 'string' || name.trim().length === 0) {
			throw new Error('Invalid player name');
		}
	}

	getBombCounter(): number {
		return this.bombCounter;
	}

	getRoundNumber(): number {
		return this.roundNumber;
	}

	private startNewRound(): void {
		this.bombCounter = 5;
		this.roundNumber++;

		// Keep players in the lobby but reset their positions to square 0
		const players = Array.from(this.lobby);
		this.initializeSquares();

		// Place all players back in square 0
		for (const player of players) {
			this.squares[0].players.add(player);
			this.squares[0].totalBalancePoints += player.balance;
		}
	}

	private checkForBombResult(): GameResult | null {
		if (this.bombCounter === 0) {
			// Find highest balance
			const balances = this.squares.map((square) => square.totalBalancePoints);
			const maxBalance = Math.max(...balances);

			// Find all squares with the highest balance
			const losingSquares = balances
				.map((balance, index) => (balance === maxBalance ? index : -1))
				.filter((index) => index !== -1);

			const result: GameResult = {
				type: 'BOMB',
				losingSquares,
				isDraw: losingSquares.length > 1,
				totalBalances: balances,
				roundNumber: this.roundNumber // Added round number to result
			};

			// Start new round automatically
			this.startNewRound();

			return result;
		}
		return null;
	}

	resetGame(): void {
		this.bombCounter = 5;
		this.roundNumber = 1;
		this.lobby = new Set();
		this.initializeSquares();
	}

	// Rest of the methods remain the same...

	getGameState(): GameState {
		return {
			squares: this.squares,
			bombCounter: this.bombCounter,
			roundNumber: this.roundNumber
		};
	}

	getSerializableGameState(): GameState {
		return {
			squares: this.squares.map((square) => ({
				players: Array.from(square.players),
				totalBalancePoints: square.totalBalancePoints
			})),
			bombCounter: this.bombCounter,
			roundNumber: this.roundNumber
		};
	}
}
