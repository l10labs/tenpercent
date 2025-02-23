import type { PageServerLoad } from './$types';
import { gameManager } from '$lib/server/gameStore';

export const load: PageServerLoad = async () => {
	return {
		...gameManager.getGameState()
	};
};
