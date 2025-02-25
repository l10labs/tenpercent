<script lang="ts">
	import { onMount } from 'svelte';

	let showContent = $state(false);

	onMount(() => {
		setTimeout(() => {
			showContent = true;
		}, 100);
	});
</script>

<div class="flex min-h-[50vh] flex-col items-center justify-center gap-6 px-4 sm:gap-8">
	<h1 class="max-w-[90%] text-center text-xl sm:max-w-[600px] sm:text-2xl md:text-3xl">
		<div class="flex flex-col items-center gap-2">
			<span
				class="scale-0 opacity-0 transition-all duration-1000"
				class:scale-100={showContent}
				class:opacity-100={showContent}
				style="transition-delay: 0ms"
			>
				Ten Percent Fun
			</span>
			<span
				class="scale-0 opacity-0 transition-all duration-1000"
				class:scale-100={showContent}
				class:opacity-100={showContent}
				style="transition-delay: 1500ms"
			>
				for Respectable Degens
			</span>
		</div>
	</h1>
	<a
		href="/play"
		class="scale-0 opacity-0 transition-all duration-1000 hover:-translate-y-1"
		class:scale-100={showContent}
		class:opacity-100={showContent}
		style="transition-delay: 3000ms"
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
