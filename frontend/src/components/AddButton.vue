<template>
  <b-button
    variant="outline-secondary"
    v-b-popover.hover.top="this.tooltip"
    v-on="$listeners"
    :class="this.checked ? 'checked' : 'unchecked'"
  >
    <div v-if="this.checked">
      <font-awesome-icon icon="check-circle" class="checked"/>
    </div>
    <div v-if="!this.checked">
      <font-awesome-icon icon="plus-circle" class="unchecked"/>
    </div>
  </b-button>
</template>

<script>
export default {
  props: {
    tooltip: String,
    checked: Boolean,
  },
};
</script>

<style scoped>

.checked {
  color: white;
  background-color: green;
}

.unchecked {
  color: grey;
}

</style>
