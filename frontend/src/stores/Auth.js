import vueAuth from '../auth';

export default {

  // You can use it as state property
  state: {
    isAuthenticated: false,
  },

  // You can use it as a state getter function (probably the best solution)
  getters: {
    isAuthenticated() {
      return vueAuth.isAuthenticated();
    },
  },

  // Mutation for when you use it as state property
  mutations: {
    isAuthenticated(state, payload) {
      state.isAuthenticated = payload.isAuthenticated;
    },
  },

  actions: {

    // Perform VueAuthenticate login using Vuex actions
    login(context/* , payload */) {
      console.log('Hello');
      vueAuth.login(/* payload.user, payload.requestOptions */).then(() => {
        context.commit('isAuthenticated', {
          isAuthenticated: vueAuth.isAuthenticated(),
        });
      });
    },
  },
};
