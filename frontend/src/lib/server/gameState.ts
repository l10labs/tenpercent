import type { Player, Square, GameResult, GameState, SerializableGameState } from '$lib/types';

export class Game {
	private squares: Square[] = [];
	private lobby: Set<Player> = new Set();
	private bombCounter: number = 5;
	private roundNumber: number = 1;
	private previousRoundResult: GameResult | null = null;

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
		// Reset bomb counter for new round
		this.bombCounter = 5;
		this.roundNumber++;

		// No need to update totalBalancePoints here since it's already done in checkForBombResult
		// We only need to update if players move between rounds
		this.squares.forEach(square => {
			square.totalBalancePoints = Array.from(square.players)
				.reduce((total, player) => total + player.balance, 0);
		});
	}

	private checkForBombResult(): GameResult | null {
		if (this.bombCounter === 0) {
			const balances = this.squares.map((square) => square.totalBalancePoints);
			const maxBalance = Math.max(...balances);

			const losingSquares = balances
				.map((balance, index) => (balance === maxBalance ? index : -1))
				.filter((index) => index !== -1);

			// Get all players in losing squares
			const losingPlayers: Player[] = [];
			const safePlayers: Player[] = [];
			let totalPenalty = 0;
			let totalSafeBalance = 0;

			// Separate losing and safe players, calculate penalties
			this.squares.forEach((square, index) => {
				const players = Array.from(square.players);
				if (losingSquares.includes(index)) {
					losingPlayers.push(...players);
				} else {
					safePlayers.push(...players);
					totalSafeBalance += players.reduce((sum, p) => sum + p.balance, 0);
				}
			});

			// Apply 10% penalty to losing players and calculate total penalty
			losingPlayers.forEach(player => {
				const penalty = player.balance * 0.1; // 10% penalty, keep decimals
				player.balance -= penalty;
				totalPenalty += penalty;
			});

			// Distribute penalties to safe players proportionally
			if (totalPenalty > 0 && totalSafeBalance > 0) {
				safePlayers.forEach(player => {
					const proportion = player.balance / totalSafeBalance;
					const reward = totalPenalty * proportion;
					player.balance += reward;
				});
			}

			// Update square balances after redistribution
			this.squares.forEach(square => {
				square.totalBalancePoints = Array.from(square.players)
					.reduce((total, player) => total + player.balance, 0);
			});

			const result: GameResult = {
				type: 'BOMB',
				losingSquares,
				isDraw: losingSquares.length > 1,
				totalBalances: balances,
				roundNumber: this.roundNumber,
				penaltyAmount: totalPenalty,
				affectedPlayers: {
					losing: losingPlayers.map(p => ({
						name: p.name,
						penalty: p.balance * 0.1 // Keep exact penalty amount
					})),
					safe: safePlayers.map(p => ({
						name: p.name,
						reward: totalPenalty * (p.balance / totalSafeBalance) // Keep exact reward amount
					}))
				}
			};

			// Store current result before starting new round
			this.previousRoundResult = result;

			// Start new round - this will reset the bomb counter and increment round number
			this.startNewRound();

			return result;
		}
		return null;
	}

	joinGame(name: string): void {
		this.validatePlayerName(name);

		// Check if player already exists by name
		if (this.findPlayerByName(name)) {
			throw new Error('Player already in game');
		}

		const player: Player = {
			name: name.trim(),
			balance: 10
		};

		this.lobby.add(player);
		this.squares[0].players.add(player);
		this.squares[0].totalBalancePoints += player.balance;
	}

	moveToSquare(playerName: string, toSquare: number): GameResult | null {
		this.validatePlayerName(playerName);

		if (this.bombCounter === 0) {
			throw new Error('Game is over - bomb has exploded!');
		}

		if (toSquare < 0 || toSquare >= 4) {
			throw new Error('Invalid square index');
		}

		let fromSquare = -1;
		let playerToMove: Player | null = null;

		// Find the player's current square
		for (let i = 0; i < this.squares.length; i++) {
			for (const p of this.squares[i].players) {
				if (p.name === playerName) {
					fromSquare = i;
					playerToMove = p;
					break;
				}
			}
			if (fromSquare !== -1) break;
		}

		if (!playerToMove) {
			throw new Error('Player not found in any square. Join the game first.');
		}

		if (fromSquare === toSquare) {
			throw new Error('Player is already in this square');
		}

		// Move the player
		this.squares[fromSquare].players.delete(playerToMove);
		this.squares[fromSquare].totalBalancePoints -= playerToMove.balance;
		this.squares[toSquare].players.add(playerToMove);
		this.squares[toSquare].totalBalancePoints += playerToMove.balance;

		// Decrement bomb counter after successful move
		this.bombCounter--;

		// Check for bomb result
		return this.checkForBombResult();
	}

	getSquare(index: number): Square {
		if (index < 0 || index >= 4) {
			throw new Error('Invalid square index');
		}
		return this.squares[index];
	}

	isPlayerInGame(name: string): boolean {
		return this.findPlayerByName(name) !== null;
	}

	getCurrentSquare(playerName: string): number {
		for (let i = 0; i < this.squares.length; i++) {
			if (Array.from(this.squares[i].players).some((p) => p.name === playerName)) {
				return i;
			}
		}
		return -1;
	}

	getPreviousRoundResult(): GameResult | null {
		return this.previousRoundResult;
	}

	resetGame(): void {
		this.bombCounter = 5;
		this.roundNumber = 1;
		this.lobby = new Set();
		this.previousRoundResult = null; // Reset previous round result
		this.initializeSquares();
	}

	getGameState(): GameState {
		return {
			squares: this.squares,
			bombCounter: this.bombCounter,
			roundNumber: this.roundNumber,
			previousRoundResult: this.previousRoundResult // Include in game state
		};
	}

	getSerializableGameState(): SerializableGameState {
		return {
			squares: this.squares.map((square) => ({
				players: Array.from(square.players),
				totalBalancePoints: square.totalBalancePoints
			})),
			bombCounter: this.bombCounter,
			roundNumber: this.roundNumber,
			previousRoundResult: this.previousRoundResult // Include in serializable state
		};
	}
}
