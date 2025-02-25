<script lang="ts">
	import ControllerButton from '$lib/components/ControllerButton.svelte';
</script>

<div class="flex min-h-screen items-center justify-center bg-black">
	<div class="flex flex-col items-center justify-center">
		<h1 class="mb-12 text-center text-7xl font-bold text-white">Ten Percent</h1>
		<div class="flex justify-center">
			<ControllerButton />
		</div>
	</div>
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		overflow: hidden;
		background-color: black;
	}
</style>
