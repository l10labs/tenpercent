import { json } from '@sveltejs/kit';
import { gameStateManager } from '$lib/server/gameState';

export async function GET() {
	return json(gameStateManager.getGameState());
}

export async function POST({ request }) {
	const data = await request.json();
	const { action, playerId, playerName, squareIndex } = data;

	switch (action) {
		case 'join':
			gameStateManager.addPlayer(playerId, playerName);
			break;
		case 'move':
			gameStateManager.makeMove(playerId, squareIndex);
			break;
	}

	return json(gameStateManager.getGameState());
}
