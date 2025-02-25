<script lang="ts">
	import GameGrid from '$lib/components/GameGrid.svelte';
	import { onMount } from 'svelte';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';

	let showGrid = $state(false);

	onMount(() => {
		// Small delay to ensure page transition is complete
		setTimeout(() => {
			showGrid = true;
		}, 100);
	});
</script>

{#if controllerStatus.is_connected}
	<GameGrid {showGrid} />
{:else}
	<div class="flex h-screen items-center justify-center">
		<h1 class="text-2xl">Please connect via controller</h1>
	</div>
{/if}
