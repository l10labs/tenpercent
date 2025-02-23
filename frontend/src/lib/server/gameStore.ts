import { Game } from './gameState';
import type { GameState, GameError, SerializableGameState, GameResult } from '$lib/types';

// Define error codes as constants
export const ErrorCodes = {
	RESET_ERROR: 'RESET_ERROR',
	VALIDATION_ERROR: 'VALIDATION_ERROR',
	PERSISTENCE_ERROR: 'PERSISTENCE_ERROR',
	RECOVERY_ERROR: 'RECOVERY_ERROR',
	JOIN_ERROR: 'JOIN_ERROR',
	MOVE_ERROR: 'MOVE_ERROR',
	GAME_ERROR: 'GAME_ERROR'
} as const;

class GameManager {
	private static instance: GameManager;
	private game: Game;
	private lastError: GameError | null = null;
	private gameHistory: GameResult[] = [];

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

	public getGameState(): SerializableGameState {
		return this.game.getSerializableGameState();
	}

	public resetGame(): void {
		try {
			this.game = new Game();
			this.lastError = null;
			this.gameHistory = [];
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.RESET_ERROR,
				message: (error as Error).message
			};
			throw error;
		}
	}

	public getLastError(): GameError | null {
		return this.lastError;
	}

	public clearError(): void {
		this.lastError = null;
	}

	public getGameHistory(): GameResult[] {
		return this.gameHistory;
	}

	public addToHistory(result: GameResult): void {
		this.gameHistory.push(result);
	}

	public isGameValid(): boolean {
		try {
			const state = this.game.getSerializableGameState();
			return (
				state.bombCounter >= 0 &&
				state.roundNumber > 0 &&
				state.squares.length === 4 &&
				state.squares.every(
					(square) => typeof square.totalBalancePoints === 'number' && Array.isArray(square.players)
				)
			);
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.VALIDATION_ERROR,
				message: (error as Error).message
			};
			return false;
		}
	}

	public async persistGameState(): Promise<void> {
		try {
			const state = this.game.getSerializableGameState();
			// Implement persistence logic here (e.g., to database or file)
			// For now, just storing in memory
			console.log('Game state persisted:', state);
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.PERSISTENCE_ERROR,
				message: (error as Error).message
			};
			throw error;
		}
	}

	public async recoverGameState(): Promise<void> {
		try {
			// Implement recovery logic here
			// For now, just resetting the game
			this.resetGame();
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.RECOVERY_ERROR,
				message: (error as Error).message
			};
			throw error;
		}
	}

	public async joinGame(playerName: string): Promise<void> {
		try {
			this.game.joinGame(playerName);
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.JOIN_ERROR,
				message: (error as Error).message
			};
			throw error;
		}
	}

	public async movePlayer(playerName: string, toSquare: number): Promise<GameResult | null> {
		try {
			const result = this.game.moveToSquare(playerName, toSquare);
			if (result) {
				this.addToHistory(result);
			}
			return result;
		} catch (error) {
			this.lastError = {
				code: ErrorCodes.MOVE_ERROR,
				message: (error as Error).message
			};
			throw error;
		}
	}

	public getPlayerCurrentSquare(playerName: string): number {
		return this.game.getCurrentSquare(playerName);
	}

	public isPlayerInGame(playerName: string): boolean {
		return this.game.isPlayerInGame(playerName);
	}

	public getBombCounter(): number {
		return this.game.getBombCounter();
	}

	public getRoundNumber(): number {
		return this.game.getRoundNumber();
	}
}

// Export singleton instance
export const gameManager = GameManager.getInstance();

// Error handling utilities
export const handleGameError = (error: Error): GameError => {
	return {
		code: ErrorCodes.GAME_ERROR,
		message: error.message
	};
};

// Type guards
export const isGameError = (error: unknown): error is GameError => {
	return typeof error === 'object' && error !== null && 'code' in error && 'message' in error;
};

// Helper functions
export function createGameError(code: keyof typeof ErrorCodes, message: string): GameError {
	return {
		code: ErrorCodes[code],
		message
	};
}

export function logGameError(error: GameError): void {
	console.error(`[${error.code}] ${error.message}`);
}

export function getErrorMessage(error: unknown): string {
	if (isGameError(error)) {
		return `${error.code}: ${error.message}`;
	}
	return error instanceof Error ? error.message : 'Unknown error occurred';
}
