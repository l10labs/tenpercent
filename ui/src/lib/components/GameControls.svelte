<script lang="ts">
	import { joinPit, controllerStatus } from '$lib/stores/controller_state.svelte';
	let { showGrid } = $props();

	async function handleJoinGame() {
		if (!controllerStatus.sharedController) {
			console.log('no controller');
			return;
		}
		await joinPit(controllerStatus.sharedController);
	}
</script>

<div class="flex gap-4">
	<button
		onclick={handleJoinGame}
		class="scale-0 rounded border border-gray-800 px-6 py-2 text-sm opacity-0 transition-all duration-500 hover:bg-gray-50"
		class:scale-100={showGrid}
		class:opacity-100={showGrid}
		style="transition-delay: 0ms"
	>
		Join Pit
	</button>
	<button
		disabled
		class="scale-0 cursor-not-allowed rounded border border-gray-300 px-6 py-2 text-sm text-gray-400 opacity-0 transition-all duration-500"
		class:scale-100={showGrid}
		class:opacity-100={showGrid}
		style="transition-delay: 150ms"
	>
		Exit Pit (Coming Soon)
	</button>
</div>
