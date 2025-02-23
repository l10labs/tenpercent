import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { gameManager } from '$lib/server/gameStore';

export const GET: RequestHandler = async () => {
	try {
		const history = gameManager.getGameHistory();
		return json({
			success: true,
			history
		});
	} catch (e) {
		return json(
			{
				success: false,
				error: 'Failed to get game history',
				history: []
			},
			{ status: 500 }
		);
	}
};
