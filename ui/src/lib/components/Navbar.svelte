<script lang="ts">
	import ControllerButton from './ControllerButton.svelte';
</script>

<nav>
	<div class="nav-content">
		<div class="logo">
			<!-- placeholder for future logo or nav items -->
		</div>
		<div class="nav-right">
			<div class="button-container">
				<ControllerButton />
			</div>
		</div>
	</div>
</nav>

<style>
	nav {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		height: 80px;
		padding: 0 32px;
		background: rgba(255, 255, 255, 0.95);
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
		backdrop-filter: blur(10px);
	}

	.nav-content {
		max-width: 1200px;
		height: 100%;
		margin: 0 auto;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.nav-right {
		display: flex;
		align-items: center;
	}

	.button-container :global(button) {
		transform: scale(2);
		transition: transform 0.2s ease;
	}

	.button-container :global(button:hover) {
		transform: scale(2.1);
	}
</style>
