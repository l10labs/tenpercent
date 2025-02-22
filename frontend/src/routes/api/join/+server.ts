import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { gameManager } from '$lib/server/gameStore';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { playerName } = await request.json();

		if (typeof playerName !== 'string') {
			return json({ error: 'Invalid player name' }, { status: 400 });
		}

		const game = gameManager.getGame();
		game.joinGame(playerName);

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
