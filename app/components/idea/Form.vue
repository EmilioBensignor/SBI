<template>
  <span />
</template>

<script setup>
defineProps({
  idea: { type: Object, required: true },
})
defineEmits(['saved'])
</script>
