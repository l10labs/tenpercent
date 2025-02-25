<script lang="ts">
	let { showGrid } = $props();

	let zero = $state(0);
	// Derived states for individual balances
	let s1_balance = $derived(zero);
	let s2_balance = $derived(zero);
	let s3_balance = $derived(zero);
	let s4_balance = $derived(zero);

	function formatDollar(amount: number): string {
		return `$${amount.toFixed(2)}`;
	}
</script>

<div class="w-full max-w-[480px] px-4 sm:px-0">
	<div class="grid grid-cols-2 gap-3 sm:gap-6">
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 300ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s1_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 450ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s2_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 600ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s3_balance)}</span>
		</div>
		<div
			class="flex aspect-square w-full max-w-[232px] scale-0 items-center justify-center rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 750ms"
		>
			<span class="text-base font-medium sm:text-xl">{formatDollar(s4_balance)}</span>
		</div>
	</div>
</div>
