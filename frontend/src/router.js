import Vue from 'vue';
import Router from 'vue-router';
import Welcome from './views/Welcome.vue';
import Recommendations from './views/Recommendations.vue';
import AddFavorites from './views/AddFavorites.vue';
import store from './store';
import config from './config';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'welcome',
      component: Welcome,
    },
    {
      path: '/recommendations/:userId',
      name: 'recommendations',
      component: Recommendations,
      beforeEnter: (to, from, next) => {
        // Only go to our recommendations if the user has enough favorites and neighbors to
        // be able to generate good recommendations. Otherwise take them to a page where they
        // can add some favorites first
        if ((store.state.welcome.user.numFavorites >= config.minNumFavoritesForRecommendations)
          && (store.state.welcome.user.numNeighbors >= config.minNumNeighborsForRecommendations)) {
          next();
        } else {
          next({
            name: 'add-favorites',
            params: { userId: to.params.userId },
          });
        }
      },
    },
    {
      path: '/add-favorites/:userId',
      name: 'add-favorites',
      component: AddFavorites,
      beforeEnter: (to, from, next) => {
        // Don't let someone go here if they have enough favorites to generate good recommendations
        if ((store.state.welcome.user.numFavorites >= config.minNumFavoritesForRecommendations)
          && (store.state.welcome.user.numNeighbors >= config.minNumNeighborsForRecommendations)) {
          next({
            name: 'recommendations',
            params: { userId: to.params.userId }, // Just use default number of recommendations because there's no other numbers available here
          });
        } else {
          next();
        }
      },
    },
  ],
});
