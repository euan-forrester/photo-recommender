<template>
  <div>
    <b-alert variant="danger" :show="true">
      You need to add more favorites before we can give you recommendations!
    </b-alert>
  </div>
</template>

<script>

export default {
  data() {
    return {
      userId: '',
      userAuthenticated: false,
    };
  },
  async mounted() {
    // console.log('Hello from add favorites');
    // this.userId = this.$route.params.userId;
    // this.userAuthenticated = (this.$store.getters.isAuthenticated());
    // console.log('Finished mounting add favorites');
  },
};
</script>

<style scoped>

</style>
