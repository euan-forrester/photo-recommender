<template>
  <div>
    <div v-if="!userAuthenticated">
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="notenoughfavorites">
          <h3>
            Sorry, {{ userName }} doesn't have enough favorites to generate any recommendations.
          </h3>
        </b-col>
      </b-row>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="minnumfavorites">
          <h4>
            They have {{ numFavorites }} favorites from {{ numNeighbors }} different users, but need at least {{ appConfig.minNumFavoritesForRecommendations }} favorites from at least {{ appConfig.minNumNeighborsForRecommendations }} different users.
          </h4>
        </b-col>
      </b-row>
      <b-row align-h="center">
        <b-col xs=12 sm=8 md=6 class="backtowelcome">
          <h4>
            <router-link to="/">Try someone else</router-link>
          </h4>
        </b-col>
      </b-row>
    </div>
    <div v-else>
      Dude you need some recommendations
    </div>
  </div>
</template>

<style scoped>
.notenoughfavorites {

}

.minnumfavorites {
  margin-top: 30px;
}

.backtowelcome {
  margin-top: 30px;
}
</style>

<script>

export default {
  data() {
    return {
      userName: '',
      userAuthenticated: false,
      numFavorites: 0,
      numNeighbors: 0,
    };
  },
  async mounted() {
    this.userName = this.$store.state.welcome.user.name;
    this.userAuthenticated = this.$store.getters.isAuthenticated();
    this.numFavorites = this.$store.state.welcome.user.numFavorites;
    this.numNeighbors = this.$store.state.welcome.user.numNeighbors;
  },
};
</script>
