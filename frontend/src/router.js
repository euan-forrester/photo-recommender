import Vue from 'vue';
import Router from 'vue-router';
import Welcome from './views/Welcome.vue';
import Login from './views/Login.vue';
import Recommendations from './views/Recommendations.vue';

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/login',
      name: 'login',
      component: Login,
    },
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
  ],
});
