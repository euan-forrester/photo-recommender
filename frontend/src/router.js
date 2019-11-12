import Vue from 'vue';
import Router from 'vue-router';
import Welcome from './views/Welcome.vue';
import Recommendations from './views/Recommendations.vue';
import AddFavorites from './views/AddFavorites.vue';

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
    },
    {
      path: '/add-favorites/:userId',
      name: 'add-favorites',
      component: AddFavorites,
    },
  ],
});
