// src/routes/+page.server.ts
import type { Actions, PageServerLoad } from './$types';
import { gameManager } from '$lib/server/gameStore';
import { error } from '@sveltejs/kit';

export const load: PageServerLoad = () => {
	const game = gameManager.getGame();
	const squares = [];
	for (let i = 0; i < 4; i++) {
		const square = game.getSquare(i);
		squares.push({
			players: Array.from(square.players), // Convert Set to Array for serialization
			totalBalancePoints: square.totalBalancePoints
		});
	}

	return {
		squares
	};
};

export const actions: Actions = {
	join: async ({ request }) => {
		const data = await request.formData();
		const playerName = data.get('playerName') as string;

		try {
			const game = gameManager.getGame();
			game.joinGame(playerName);
			return { success: true };
		} catch (e) {
			throw error(400, (e as Error).message);
		}
	},

	move: async ({ request }) => {
		const data = await request.formData();
		const playerName = data.get('playerName') as string;
		const toSquare = parseInt(data.get('toSquare') as string);

		try {
			const game = gameManager.getGame();
			game.moveToSquare(playerName, toSquare);
			return { success: true };
		} catch (e) {
			throw error(400, (e as Error).message);
		}
	},

	reset: async () => {
		gameManager.resetGame();
		return { success: true };
	}
};
