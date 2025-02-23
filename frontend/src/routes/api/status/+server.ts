import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { GameResponse } from '$lib/types';
import { gameManager } from '$lib/server/gameStore';

export const GET: RequestHandler = async () => {
	try {
		return json({
			success: true,
			...gameManager.getGameState()
		});
	} catch (e) {
		return json(
			{
				success: false,
				error: 'Failed to get game status',
				...gameManager.getGameState()
			},
			{ status: 500 }
		);
	}
};
