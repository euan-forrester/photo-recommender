import Vue from 'vue';
import Vuex from 'vuex';

import RepositoryFactory from './repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    userId: '',
  },
  mutations: {
    setUserId(state, userId) {
      state.userId = userId;
    },
  },
  actions: {
    getUserIdFromUrl({ commit }, userUrl) {
      FlickrRepository.getUserIdFromUrl(userUrl)
        .then((response) => {
          console.log('Called Flickr successfully! Got back response', response);
          const userId = 'FixMe';
          commit('setUserId', userId);
        })
        .catch((error) => {
          console.log('Got back an error when calling Flickr', error);
        });
    },
  },
});
