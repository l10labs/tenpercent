// Basic player interface
export interface Player {
	name: string;
	balance: number;
}

// Base Square interface using Set for players
export interface Square {
	players: Set<Player>;
	totalBalancePoints: number;
}

// Serializable version of Square for API responses
export interface SerializableSquare {
	players: Player[];
	totalBalancePoints: number;
}

// Game result when bomb counter hits zero
export interface GameResult {
	type: 'BOMB';
	losingSquares: number[];
	isDraw: boolean;
	totalBalances: number[];
	roundNumber: number;
}

// Server-side game state
export interface GameState {
	squares: Square[];
	bombCounter: number;
	roundNumber: number;
	previousRoundResult: GameResult | null;
}

// Serializable game state for API responses
export interface SerializableGameState {
	squares: SerializableSquare[];
	bombCounter: number;
	roundNumber: number;
	previousRoundResult: GameResult | null;
}

// API response format
export interface GameResponse extends SerializableGameState {
	success: boolean;
	error?: string;
	gameResult?: GameResult;
}

// API request types
export interface JoinGameRequest {
	playerName: string;
}

export interface MoveRequest {
	playerName: string;
	toSquare: number;
}

// Specific API response types
export interface JoinGameResponse extends GameResponse {
	playerJoined: string;
}

export interface MoveResponse extends GameResponse {
	playerMoved: string;
	fromSquare: number;
	toSquare: number;
}

// Error handling types
export interface GameError {
	code: string;
	message: string;
}

// Game status enum
export enum GameStatus {
	WAITING = 'waiting',
	IN_PROGRESS = 'in_progress',
	ROUND_OVER = 'round_over'
}

// Valid square indices
export type SquareIndex = 0 | 1 | 2 | 3;

// SSE Event types
export interface GameUpdateEvent extends SerializableGameState {
	timestamp: number;
	lastAction?: {
		type: 'JOIN' | 'MOVE' | 'RESET';
		player?: string;
		data?: any;
	};
}

// Type guards
export function isGameError(error: unknown): error is GameError {
	return typeof error === 'object' && error !== null && 'code' in error && 'message' in error;
}

export function isValidSquareIndex(index: number): index is SquareIndex {
	return index >= 0 && index <= 3;
}

export function isPlayer(obj: unknown): obj is Player {
	return (
		typeof obj === 'object' &&
		obj !== null &&
		'name' in obj &&
		'balance' in obj &&
		typeof (obj as Player).name === 'string' &&
		typeof (obj as Player).balance === 'number'
	);
}

// Utility types
export type GameActionType = 'JOIN' | 'MOVE' | 'RESET';

export interface GameAction {
	type: GameActionType;
	player?: string;
	data?: any;
	timestamp: number;
}

export interface GameHistory {
	actions: GameAction[];
	currentRound: number;
}

// Constants
export const INITIAL_BALANCE = 10;
export const INITIAL_BOMB_COUNTER = 5;
export const TOTAL_SQUARES = 4;

// Configuration interface
export interface GameConfig {
	initialBalance: number;
	initialBombCounter: number;
	totalSquares: number;
	minPlayers: number;
	maxPlayers: number;
}

// Default configuration
export const DEFAULT_GAME_CONFIG: GameConfig = {
	initialBalance: INITIAL_BALANCE,
	initialBombCounter: INITIAL_BOMB_COUNTER,
	totalSquares: TOTAL_SQUARES,
	minPlayers: 2,
	maxPlayers: 8
};
