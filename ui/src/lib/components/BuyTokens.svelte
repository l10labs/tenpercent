<script lang="ts">
	function handleBuyTokens() {
		// Add buy tokens logic here
		console.log('Buy tokens clicked');
	}
</script>

<button
	on:click={handleBuyTokens}
	class="rounded border border-gray-800 px-4 py-1 text-xs hover:bg-gray-50"
>
	Buy Tokens
</button>
