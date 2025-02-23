import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { GameResponse } from '$lib/types';
import { gameManager, handleGameError } from '$lib/server/gameStore';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { playerName, toSquare } = await request.json();

		if (typeof playerName !== 'string' || typeof toSquare !== 'number') {
			return json(
				{
					success: false,
					error: 'Invalid parameters',
					...gameManager.getGameState()
				},
				{ status: 400 }
			);
		}

		const gameResult = await gameManager.movePlayer(playerName, toSquare);
		return json({
			success: true,
			...gameManager.getGameState(),
			gameResult
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
