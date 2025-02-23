import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { GameResponse } from '$lib/types';
import { gameManager, handleGameError } from '$lib/server/gameStore';

export const POST: RequestHandler = async () => {
	try {
		gameManager.resetGame();
		return json({
			success: true,
			...gameManager.getGameState()
		});
	} catch (e) {
		const error = handleGameError(e as Error);
		return json(
			{
				success: false,
				error: error.message,
				...gameManager.getGameState()
			},
			{ status: 400 }
		);
	}
};
