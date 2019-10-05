<template>
  <b-col cols=2 class="mb-3, recommendation">
    <b-alert variant="danger" :show="this.encounteredError">
      Could not get information about this user. Please try again later
    </b-alert>
    <div v-if="!this.encounteredError">
      <transition name="fade">
        <div v-if="this.visible">
          <b-link :href="this.personInfo.profileUrl">
            <b-row align-h="center">
              <b-img left fluid rounded="circle" class="photo" :src="personInfo.iconUrl"></b-img>
            </b-row>
            <b-row align-h="center">
              <div class="personname">
                {{ personInfo.realName }}
              </div>
            </b-row>
          </b-link>
          <div v-if="this.userAuthenticated">
            <DismissButton @click="onDismiss()" class="dismissbutton"></DismissButton>
            <AddButton
              class="addbutton"
              tooltip="To add a new contact please visit their page and add them from there.
              The Flickr API unfortunately doesn't support adding contacts so we can't add them from here."
              v-bind:checked="false"
            ></AddButton>
          </div>
        </div>
      </transition>
    </div>
  </b-col>
</template>

<style scoped>
.dismissbutton {
  position: absolute;
  top: 0px;
  right: 4px;
}
.addbutton {
  position: absolute;
  top: 4px;
  left: 4px;
}
.recommendation {
  background-color: Gainsboro;
  margin: 2px;
  padding-left: 25px;
  padding-right: 25px;
  border-radius: 10px;
}
.photo {
  padding-top: 5px;
}
.personname {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.fade-enter-active, .fade-leave-active {
  transition: opacity .5s;
}
.fade-enter, .fade-leave-to /* .fade-leave-active below version 2.1.8 */ {
  opacity: 0;
}
</style>

<script>
import DismissButton from './DismissButton.vue';
import AddButton from './AddButton.vue';

export default {
  components: {
    DismissButton,
    AddButton,
  },
  props: {
    userId: String,
    recommendationUserId: String,
    userAuthenticated: Boolean,
  },
  data() {
    return {
      personInfo: {},
      encounteredError: false,
      visible: true,
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

      await this.$store.dispatch('getPersonInfo', this.recommendationUserId);

      this.personInfo = this.$store.state.recommendations.personInfo[this.recommendationUserId];
    } catch (error) {
      this.encounteredError = true;
    }
  },
  methods: {
    async onDismiss() {
      this.visible = false;

      await this.$store.dispatch('dismissUserRecommendation', { userId: this.userId, dismissedUserId: this.recommendationUserId });
    },
  },
};
</script>
