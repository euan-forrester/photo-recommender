import Vue from 'vue';
import Vuex from 'vuex';

import RepositoryFactory from './repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');
const UsersRepository = RepositoryFactory.get('users');

Vue.use(Vuex);

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default new Vuex.Store({
  state: {
    user: {
      id: '',
      name: '',
      recommendations: [],
    },
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
    setRecommendations(state, recommendations) {
      state.user.recommendations = recommendations;
    },
  },
  actions: {
    async getUserIdFromUrl({ commit }, userUrl) {
      const response = await FlickrRepository.getUserIdFromUrl(userUrl);

      const user = {
        id: response.data.user.id,
        name: response.data.user.username._content, // eslint-disable-line no-underscore-dangle
        recommendations: [],
      };

      commit('setUser', user);
    },
    async getRecommendationsForUser({ commit }, userId) {
      const recommendations = await UsersRepository.getRecommendations(userId);

      commit('setRecommendations', recommendations.data);
    },
  },
});
