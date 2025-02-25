<script lang="ts">
	let { showGrid } = $props();
</script>

<div class="w-[320px]">
	<div class="grid grid-cols-2 gap-4">
		<div
			class="aspect-square w-[152px] scale-0 rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 300ms"
		></div>
		<div
			class="aspect-square w-[152px] scale-0 rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 450ms"
		></div>
		<div
			class="aspect-square w-[152px] scale-0 rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 600ms"
		></div>
		<div
			class="aspect-square w-[152px] scale-0 rounded border border-gray-800 opacity-0 transition-all duration-500"
			class:scale-100={showGrid}
			class:opacity-100={showGrid}
			style="transition-delay: 750ms"
		></div>
	</div>
</div>
