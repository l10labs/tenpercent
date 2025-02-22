import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { gameManager } from '$lib/server/gameStore';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { playerName, toSquare } = await request.json();

		if (typeof playerName !== 'string' || typeof toSquare !== 'number') {
			return json({ error: 'Invalid parameters' }, { status: 400 });
		}

		const game = gameManager.getGame();
		game.moveToSquare(playerName, toSquare);

		// Return updated game state
		const squares = [];
		for (let i = 0; i < 4; i++) {
			const square = game.getSquare(i);
			squares.push({
				players: Array.from(square.players),
				totalBalancePoints: square.totalBalancePoints
			});
		}

		return json({ success: true, squares });
	} catch (e) {
		return json({ error: (e as Error).message }, { status: 400 });
	}
};
