<template>
  <b-button
    variant="outline-secondary"
    v-b-popover.hover.top="this.tooltip"
    v-on="$listeners"
  >
  +
  </b-button>
</template>

<script>
export default {
  props: {
    tooltip: String,
  },
};
</script>

<style scoped>

</style>
