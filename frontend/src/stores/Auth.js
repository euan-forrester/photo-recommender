import vueAuth from '../auth';

export default {
  getters: {
    // We don't want vuex to cache the result of this function: we want it to be reevaluated every time.
    // So, return a function, and then this getter is called as a function rather than a property:
    // https://forum.vuejs.org/t/vuex-getter-not-re-evaluating-return-cached-data/55697/5
    isAuthenticated: () => () => vueAuth.isAuthenticated(),
  },

  actions: {
    async login() {
      await vueAuth.authenticate('flickr');
    },
    async logout() {
      await vueAuth.logout();
    },
  },
};
