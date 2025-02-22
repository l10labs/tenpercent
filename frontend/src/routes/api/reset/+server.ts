import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { gameManager } from '$lib/server/gameStore';

export const POST: RequestHandler = async () => {
	try {
		const game = gameManager.getGame();
		game.resetGame();

		const gameState = game.getGameState();
		return json({
			success: true,
			squares: gameState.squares,
			bombCounter: gameState.bombCounter
		});
	} catch (e) {
		return json({ error: (e as Error).message }, { status: 400 });
	}
};
