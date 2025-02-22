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
		const gameResult = game.moveToSquare(playerName, toSquare);
		const gameState = game.getGameState();

		return json({
			success: true,
			squares: gameState.squares,
			bombCounter: gameState.bombCounter,
			gameResult
		});
	} catch (e) {
		return json({ error: (e as Error).message }, { status: 400 });
	}
};
