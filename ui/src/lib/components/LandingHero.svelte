<script lang="ts">
	import { onMount } from 'svelte';

	let visible = false;
	let showButton = false;

	onMount(() => {
		visible = true;
		setTimeout(() => {
			showButton = true;
		}, 4000); // Adjusted for longer animation sequence
	});
</script>

<div class="flex min-h-[50vh] flex-col items-center justify-center gap-6 px-4 sm:gap-8">
	<h1
		class="max-w-[90%] text-center text-xl opacity-0 transition-opacity duration-1000 sm:max-w-[600px] sm:text-2xl md:text-3xl"
		class:opacity-100={visible}
	>
		<div class="flex flex-col items-center">
			<span class="type-line-1 inline-block overflow-hidden whitespace-nowrap">
				Ten Percent Fun
			</span>
			<span class="type-line-2 inline-block overflow-hidden whitespace-nowrap">
				for the Classy Degens
			</span>
		</div>
	</h1>
	<a
		href="/play"
		class="opacity-0 transition-all duration-1000"
		class:opacity-100={showButton}
		class:hover:-translate-y-1={showButton}
	>
		<button class="rounded-md border-2 border-gray-800 px-6 py-2 text-base sm:px-8 sm:text-lg">
			Play Now
		</button>
	</a>
</div>

<style>
	@keyframes typing {
		from {
			width: 0;
		}
		to {
			width: 100%;
		}
	}

	.type-line-1 {
		animation: typing 1.5s steps(13, end);
		margin-bottom: 0.5rem;
	}

	.type-line-2 {
		animation: typing 1.5s steps(19, end);
		animation-delay: 2.5s;
		width: 0;
		animation-fill-mode: forwards;
	}
</style>
