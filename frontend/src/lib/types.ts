export interface Player {
	name: string;
	balance: number;
}

export interface Square {
	players: Set<Player>;
	totalBalancePoints: number;
}

export interface GameResult {
	type: 'BOMB';
	losingSquares: number[];
	isDraw: boolean;
	totalBalances: number[];
}

export interface GameState {
	squares: Square[];
	bombCounter: number;
}

export interface GameResponse {
	success: boolean;
	squares: Square[];
	bombCounter: number;
	gameResult?: GameResult;
	error?: string;
}
