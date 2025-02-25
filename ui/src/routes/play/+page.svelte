<script lang="ts">
	import GameGrid from '$lib/components/GameGrid.svelte';
	import { onMount } from 'svelte';

	let showGrid = $state(false);

	onMount(() => {
		// Small delay to ensure page transition is complete
		setTimeout(() => {
			showGrid = true;
		}, 100);
	});
</script>

<GameGrid {showGrid} />
