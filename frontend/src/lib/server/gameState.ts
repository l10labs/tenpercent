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

	joinGame(name: string) {
		const player: Player = {
			name: name,
			balance: 10
		};
		if (!this.lobby.has(player)) {
			this.lobby.add(player);
			this.squares[0].players.add(player);
			this.squares[0].totalBalancePoints += player.balance;
		} else {
			throw new Error('Player already in game');
		}
	}

	moveToSquare(player: string, toSquare: number) {
		if (toSquare >= 0 && toSquare < 4) {
			// Find which square the player is currently in
			let fromSquare = -1;
			for (let i = 0; i < this.squares.length; i++) {
				for (const p of this.squares[i].players) {
					if (p.name === player) {
						fromSquare = i;
						// Move the player
						this.squares[i].players.delete(p);
						this.squares[i].totalBalancePoints -= p.balance;
						this.squares[toSquare].players.add(p);
						this.squares[toSquare].totalBalancePoints += p.balance;
						break;
					}
				}
				if (fromSquare !== -1) break;
			}

			if (fromSquare === -1) {
				throw new Error('Player not found in any square. Join the game first.');
			}
		}
	}

	getSquare(index: number): Square {
		if (index >= 0 && index < 4) {
			return this.squares[index];
		}
		throw new Error('Invalid square index');
	}
}
