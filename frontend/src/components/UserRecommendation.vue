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
      // It would probably be better if we had all the information we needed about each potential
      // user recommendation in our database already. That would allow us to get information about
      // how to display them faster.
      //
      // However, it would increase the complexity of the application and its running time (getting
      // data from Flickr in puller-flickr is the slowest part, and this would mean adding an extra call
      // each time, to get the user's info as well as their faves).
      //
      // So, in the interest of keeping the system running as quickly as possible, let's just get the
      // info about how to display a user in the front end instead.

      await this.$store.dispatch('getPersonInfo', this.userId);

      this.personInfo = this.$store.state.recommendations.personInfo[this.userId];
    } catch (error) {
      this.encounteredError = true;
    }
  },
};
</script>

<style scoped>
.recommendation {
    clear: both;
}
</style>
