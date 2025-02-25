<script lang="ts">
	import ControllerButton from './ControllerButton.svelte';
	// Add any navbar-specific logic here if needed
</script>

<nav class="fixed top-0 w-full border-b bg-white">
	<div class="mx-auto max-w-7xl px-4">
		<div class="flex h-16 items-center justify-between">
			<div class="flex items-center gap-6">
				<span class="font-medium">TenPercent.fun</span>
			</div>
			<div>
				<ControllerButton />
			</div>
		</div>
	</div>
</nav>
