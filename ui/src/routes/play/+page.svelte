<script lang="ts">
	import { onMount } from 'svelte';
	import { controllerStatus } from '$lib/stores/controller_state.svelte';
	import GameControls from '$lib/components/GameControls.svelte';
	import SquareGrid from '$lib/components/SquareGrid.svelte';

	let showGrid = $state(false);

	onMount(() => {
		// Small delay to ensure page transition is complete
		setTimeout(() => {
			showGrid = true;
		}, 100);
	});
</script>

{#if controllerStatus.is_connected}
	<div class="flex flex-col items-center gap-8 pt-24">
		<GameControls {showGrid} />
		<SquareGrid {showGrid} />
	</div>
{:else}
	<div class="flex h-screen items-center justify-center">
		<h1
			class="scale-0 text-2xl opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 300ms"
		>
			Please connect via controller
		</h1>
	</div>
{/if}
