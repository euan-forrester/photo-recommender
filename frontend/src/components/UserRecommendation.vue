<template>
  <div class="recommendation">
    <b-alert variant="danger" :show="this.encounteredError">
      Could not get information about this user. Please try again later
    </b-alert>
    <div v-if="!this.encounteredError">
      <b-link :href="this.personInfo.profileUrl">
        <b-img left fluid :src="personInfo.iconUrl"></b-img>
        {{ personInfo.realName }}
      </b-link>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    userId: String,
  },
  data() {
    return {
      personInfo: {},
      encounteredError: false,
    };
  },
  async mounted() {
    try {
      await this.$store.dispatch('getPersonInfo', this.userId);

      this.personInfo = this.$store.state.personInfo[this.userId];
    } catch (error) {
      this.encounteredError = true;
      console.log("Encountered error trying to get user info: ", error);
    }
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}
</style>
