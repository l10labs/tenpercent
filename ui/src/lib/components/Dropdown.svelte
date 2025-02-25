<script lang="ts">
	import { onMount } from 'svelte';
	import { buyTokens, controllerStatus } from '$lib/stores/controller_state.svelte';

	let isOpen = $state(false);
	let dropdownRef: HTMLDivElement;

	function toggleDropdown() {
		isOpen = !isOpen;
	}

	function closeDropdown() {
		isOpen = false;
	}

	async function handleBuyTokens() {
		if (!controllerStatus.sharedController) {
			console.log('no controller');
			return;
		}
		await buyTokens(controllerStatus.sharedController);
		closeDropdown();
	}

	onMount(() => {
		function handleClickOutside(event: MouseEvent) {
			if (dropdownRef && !dropdownRef.contains(event.target as Node)) {
				closeDropdown();
			}
		}

		document.addEventListener('click', handleClickOutside);
		return () => document.removeEventListener('click', handleClickOutside);
	});
</script>

<div class="relative" bind:this={dropdownRef}>
	<button onclick={toggleDropdown} class="text-base font-medium hover:text-gray-600">
		tenpercent.fun
	</button>

	{#if isOpen}
		<div
			class="absolute top-full left-0 mt-2 w-56 rounded border border-gray-200 bg-white py-1 shadow-lg"
		>
			<a href="/" onclick={closeDropdown} class="block px-4 py-2 text-sm hover:bg-gray-50">Home</a>
			<a href="/play" onclick={closeDropdown} class="block px-4 py-2 text-sm hover:bg-gray-50"
				>Play</a
			>
			<button
				onclick={handleBuyTokens}
				class="block w-full px-4 py-2 text-left text-sm hover:bg-gray-50"
			>
				Buy Tokens
			</button>
		</div>
	{/if}
</div>
