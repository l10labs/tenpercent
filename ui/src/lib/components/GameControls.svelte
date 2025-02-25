<script lang="ts">
	let { showGrid } = $props();

	function handleJoinGame() {
		console.log('Join game clicked');
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
		Join Game
	</button>
	<button
		disabled
		class="scale-0 cursor-not-allowed rounded border border-gray-300 px-6 py-2 text-sm text-gray-400 opacity-0 transition-all duration-500"
		class:scale-100={showGrid}
		class:opacity-100={showGrid}
		style="transition-delay: 150ms"
	>
		Exit Game (Coming Soon)
	</button>
</div>
