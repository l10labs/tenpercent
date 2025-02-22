interface Player {
	name: string;
	balance: number;
}

interface Square {
	players: Set<Player>;
	totalBalancePoints: number;
}

export class Game {
	private squares: Square[] = [];
	private lobby: Set<Player> = new Set();

	constructor() {
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

	moveToSquare(playerName: string, toSquare: number): void {
		this.validatePlayerName(playerName);

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
	}

	getSquare(index: number): Square {
		if (index < 0 || index >= 4) {
			throw new Error('Invalid square index');
		}
		return this.squares[index];
	}

	// Additional helper methods
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
}
