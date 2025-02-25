<script lang="ts">
	import '$lib/styles/home.css';
</script>

<main>
	<div class="container">
		<h1>10%</h1>
	</div>
</main>

<style>
	main {
		height: 100vh;
		display: grid;
		place-items: center;
	}

	.container {
		text-align: center;
	}

	h1 {
		font-family:
			-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
		font-size: 6rem;
		font-weight: 300;
		margin-bottom: 3rem;
		letter-spacing: -0.02em;
	}

	.button-wrapper {
		display: grid;
		place-items: center;
	}

	.button-wrapper :global(button) {
		transform: scale(1.5);
	}
</style>
