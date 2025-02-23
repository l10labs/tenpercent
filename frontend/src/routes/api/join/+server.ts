import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import type { GameResponse } from '$lib/types';
import { gameManager, handleGameError } from '$lib/server/gameStore';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { playerName } = await request.json();

		if (typeof playerName !== 'string') {
			return json(
				{
					success: false,
					error: 'Invalid player name',
					...gameManager.getGameState()
				},
				{ status: 400 }
			);
		}

		await gameManager.joinGame(playerName);
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
