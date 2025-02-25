<script lang="ts">
	let { showGrid } = $props();

	function handleSquareClick(index: number) {
		console.log(`Square ${index} clicked`);
		// Add game logic here
	}
</script>

<div class="flex min-h-screen items-center justify-center px-4">
	<div class="w-1/2 max-w-2xl">
		<div class="grid aspect-square w-full grid-cols-2 gap-4">
			{#each Array(4) as _, i}
				<button
					onclick={() => handleSquareClick(i)}
					class="aspect-square w-full scale-0 border-2 border-gray-800 opacity-0 transition-all duration-500 hover:-translate-y-1 hover:bg-gray-50"
					class:scale-100={showGrid}
					class:opacity-100={showGrid}
					style="transition-delay: {i * 150}ms"
					aria-label="Game square {i + 1}"
				></button>
			{/each}
		</div>
	</div>
</div>
