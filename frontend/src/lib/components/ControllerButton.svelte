<script lang="ts">
	import controller from './controller';

	async function connect() {
		try {
			const res = await controller.connect();
			if (res) {
				let username = await controller.username();
				console.log(username);
				console.log('controller logged in i think');
			}
		} catch (e) {
			console.log(e);
		}
	}
</script>

<button
	on:click={connect}
	class="flex items-center gap-2 rounded bg-purple-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-purple-600"
>
	<span>Connect</span>
</button>
