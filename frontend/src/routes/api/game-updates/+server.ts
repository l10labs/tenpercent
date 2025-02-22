import { gameManager } from '$lib/server/gameStore';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ setHeaders }) => {
	setHeaders({
		'Content-Type': 'text/event-stream',
		'Cache-Control': 'no-cache',
		Connection: 'keep-alive'
	});

	const game = gameManager.getGame();
	const gameState = game.getGameState();

	const data = JSON.stringify({
		squares: gameState.squares,
		bombCounter: gameState.bombCounter
	});

	return new Response(`data: ${data}\n\n`, {
		headers: {
			'Content-Type': 'text/event-stream',
			'Cache-Control': 'no-cache',
			Connection: 'keep-alive'
		}
	});
};
