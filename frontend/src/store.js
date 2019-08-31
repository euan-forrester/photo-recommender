import Vue from 'vue';
import Vuex from 'vuex';

import RepositoryFactory from './repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

Vue.use(Vuex);

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default new Vuex.Store({
  state: {
    user: {
      id: '',
      name: '',
    },
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
  },
  actions: {
    async getUserIdFromUrl({ commit }, userUrl) {
      const response = await FlickrRepository.getUserIdFromUrl(userUrl);

      const user = {
        id: response.data.user.id,
        name: response.data.user.username._content, // eslint-disable-line no-underscore-dangle
      };

      commit('setUser', user);
    },
  },
});
