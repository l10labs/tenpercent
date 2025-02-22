import { gameManager } from '$lib/server/gameStore';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = ({ setHeaders }) => {
	setHeaders({
		'Content-Type': 'text/event-stream',
		'Cache-Control': 'no-cache',
		Connection: 'keep-alive'
	});

	const game = gameManager.getGame();
	const squares = [];
	for (let i = 0; i < 4; i++) {
		const square = game.getSquare(i);
		squares.push({
			players: Array.from(square.players),
			totalBalancePoints: square.totalBalancePoints
		});
	}

	return new Response(`data: ${JSON.stringify({ squares })}\n\n`, {
		headers: { 'Content-Type': 'text/event-stream' }
	});
};
