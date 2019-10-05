<template>
  <b-button
    variant="outline-secondary"
    v-b-popover.hover.top="this.tooltip"
    v-on="$listeners"
    :class="this.currentState"
  >
    <div v-if="this.currentState === 'unchecked'">
      <font-awesome-icon icon="plus-circle"/>
    </div>
    <div v-if="this.currentState === 'loading'">
      <b-spinner small/>
    </div>
    <div v-if="this.currentState === 'checked'">
      <font-awesome-icon icon="check-circle"/>
    </div>
  </b-button>
</template>

<script>
export default {
  props: {
    tooltip: String,
    currentState: String,
  },
};
</script>

<style scoped>

.unchecked {
  color: grey;
}

.loading {
  color: grey;
}

.checked {
  color: white;
  background-color: green;
}

</style>
