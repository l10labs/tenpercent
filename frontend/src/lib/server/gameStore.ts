// src/lib/server/gameStore.ts
import { Game } from './gameState';

// Singleton instance
class GameManager {
	private static instance: GameManager;
	private game: Game;

	private constructor() {
		this.game = new Game();
	}

	public static getInstance(): GameManager {
		if (!GameManager.instance) {
			GameManager.instance = new GameManager();
		}
		return GameManager.instance;
	}

	public getGame(): Game {
		return this.game;
	}

	public resetGame() {
		this.game = new Game();
	}
}

// Export a single instance
export const gameManager = GameManager.getInstance();
