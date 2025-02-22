import { Game } from './gameState';

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

export const gameManager = GameManager.getInstance();
