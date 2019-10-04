<template>
  <b-button
    variant="outline-secondary"
    v-b-popover.hover.top="this.tooltip"
    v-on="$listeners"
  >
  <font-awesome-icon icon="plus-circle" />
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
